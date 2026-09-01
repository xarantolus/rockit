import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rockit/apis/coalesce.dart';
import 'package:rockit/apis/error_details.dart';
import 'package:rockit/apis/response_cache.dart';

class APIClient {
  static final _httpClient = http.Client();

  static const _key = 'http-cache';

  static final CacheManager? _cacheManager = () {
    try {
      return CacheManager(
        Config(
          _key,
          stalePeriod: const Duration(days: 3),
          // The default of 200 is smaller than one listing page's worth of
          // work: a page of 100 launches writes the page *plus* a seeded copy
          // of each entry, so two pages already evict the first. That capped
          // search at one page however deep the background job read.
          // CacheJanitor bounds the bytes.
          maxNrOfCacheObjects: 800,
          repo: JsonCacheInfoRepository(databaseName: _key),
          fileService: HttpFileService(),
        ),
      );
    } catch (e) {
      debugPrint("Could not initialize cache manager: $e");
    }
    return null;
  }();

  /// Reads a stored response without ever touching the network, returning null
  /// when nothing has been cached for [url].
  ///
  /// This is what makes cache-first loading possible: [fetch] with
  /// `preferCache` still goes online when the cache misses, which can block a
  /// listing for ten seconds or more.
  Future<String?> readCache(Uri url) async {
    if (kIsWeb) {
      return responseCache.read(url);
    }

    try {
      final file = await _cacheManager?.getFileFromCache(url.toString());
      if (file == null) {
        return null;
      }

      return utf8.decode(await File(file.file.path).readAsBytes());
    } catch (err) {
      debugPrint("Error reading $url from cache: $err");
      return null;
    }
  }

  /// Files [body] under [url] without any request, so a later cache-first read
  /// finds it.
  ///
  /// Used to seed the per-item endpoints from a listing: a listing is fetched
  /// with `mode=detailed`, so each entry in it is exactly what that item's own
  /// endpoint would return, and the cache is keyed by URL alone.
  Future<void> writeCache(Uri url, String body) async {
    if (kIsWeb) {
      return responseCache.write(url, body);
    }

    try {
      await _cacheManager?.putFile(
        url.toString(),
        Uint8List.fromList(utf8.encode(body)),
        key: url.toString(),
      );
    } catch (err) {
      debugPrint("Error writing $url to cache: $err");
    }
  }

  /// Decodes a JSON body into the object every endpoint in this API returns.
  ///
  /// Typed as [Object] rather than `dynamic` so the cast is checked: `dynamic`
  /// would let a wrong shape flow silently into a model constructor and blow up
  /// somewhere far away instead.
  static Map<String, dynamic> asJsonObject(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    throw FormatException("Expected a JSON object, got ${value.runtimeType}");
  }

  /// Same as [readCache], but decodes the body as JSON.
  Future<Object?> readCacheJSON(Uri url) async {
    final body = await readCache(url);
    if (body == null) {
      return null;
    }

    try {
      return jsonDecode(body);
    } catch (err) {
      debugPrint("Cached response for $url is not valid JSON: $err");
      return null;
    }
  }

  Future<ErrorDetails<Object?>> fetchJSON(
    Uri url, [
    bool preferCache = false,
  ]) async {
    var details = await fetch(url, preferCache);

    return details.bubble(jsonDecode(details.data));
  }

  /// Requests that have not settled yet, keyed by URL and cache preference.
  static final _inFlight = <String, Future<ErrorDetails<String>>>{};

  Future<ErrorDetails<String>> fetch(Uri url, [bool preferCache = false]) {
    return coalesce(
      _inFlight,
      "${preferCache ? 'cache' : 'net'} $url",
      () => _fetch(url, preferCache),
    );
  }

  Future<ErrorDetails<String>> _fetch(Uri url, bool preferCache) async {
    if (preferCache) {
      try {
        if (kIsWeb) {
          final cached = await responseCache.read(url);
          if (cached != null) {
            debugPrint("Serving $url from cache because the cache is prefered");

            return ErrorDetails(cached);
          }
        }

        var file = kIsWeb
            ? null
            : await _cacheManager?.getFileFromCache(url.toString());
        if (file != null) {
          debugPrint("Serving $url from cache because the cache is prefered");
          return ErrorDetails(
            utf8.decode(await File(file.file.path).readAsBytes()),
          );
        }
      } catch (err) {
        debugPrint("Error loading ${url.toString()} from cache: $err");
      }
    }

    PackageInfo? packageInfo;

    try {
      packageInfo = await PackageInfo.fromPlatform();
    } catch (e) {
      debugPrint("Could not retrieve package info when fetching URL: $e");
    }

    Uint8List responseBytes;

    debugPrint("Fetching URL ${url.toString()}");

    ErrorType? etype;

    try {
      // At first, we try to get the response by fetching it from the web server
      var response = await _httpClient.get(
        url,
        headers: {
          "Accept": "application/json",
          if (!kIsWeb)
            "User-Agent":
                "RockItApp (${packageInfo?.packageName ?? 'Unknown'} ${packageInfo?.version ?? 'version unknown'} ${kDebugMode ? 'DEBUG' : 'RELEASE'})",
        },
      );

      debugPrint(
        "Got response for ${url.toString()}: status ${response.statusCode}",
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException("Unexpected status code ${response.statusCode}");
      }

      responseBytes = response.bodyBytes;

      if (kIsWeb) {
        await responseCache.write(url, utf8.decode(responseBytes));
      } else {
        // If everything worked, we can put the file into the cache. That way, we can
        // access it in case of no internet or a rate limit
        try {
          await _cacheManager?.putFile(
            url.toString(),
            responseBytes,
            key: url.toString(),
          );
        } catch (e) {
          debugPrint("Error putting ${url.toString()} into cache: $e");
        }
      }
    } catch (e) {
      debugPrint("Error fetching ${url.toString()}: $e");

      if (kIsWeb) {
        // Same reasoning as below: offline, or the hourly limit is spent.
        final cached = await responseCache.read(url);
        if (cached == null) {
          rethrow;
        }

        debugPrint("Serving $url from cache because the request didn't work");

        return ErrorDetails(cached, ErrorType.cachedFallback);
      }

      // We likely have no internet, or we have hit a rate limit
      try {
        // Now we can try to get this content from the cache.
        var file = await _cacheManager?.getFileFromCache(url.toString());
        if (file == null) {
          throw Exception("This URL hasn't been cached before");
        }

        debugPrint("Serving $url from cache because the request didn't work");
        responseBytes = await File(file.file.path).readAsBytes();

        etype = ErrorType.cachedFallback;
      } catch (ec) {
        throw Exception(
          "Cannot load data from ${url.toString()}: $e.\nCache was also unavailable (reason: $ec)",
        );
      }
    }

    // We need to decode utf8, else text like "äöü" will be decoded wrong
    return ErrorDetails(utf8.decode(responseBytes), etype);
  }
}
