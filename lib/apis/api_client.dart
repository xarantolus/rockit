import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rockit/apis/error_details.dart';

class APIClient {
  static final _httpClient = http.Client();

  static const _key = 'http-cache';

  static final CacheManager? _cacheManager = () {
    try {
      return CacheManager(
        Config(
          _key,
          stalePeriod: const Duration(days: 3),
          repo: JsonCacheInfoRepository(databaseName: _key),
          fileService: HttpFileService(),
        ),
      );
    } catch (e) {
      debugPrint("Could not initialize cache manager: $e");
    }
    return null;
  }();

  Future<ErrorDetails<dynamic>> fetchJSON(
    Uri url, [
    bool preferCache = false,
  ]) async {
    var details = await fetch(url, preferCache);

    return details.bubble(jsonDecode(details.data));
  }

  Future<ErrorDetails<String>> fetch(Uri url, [bool preferCache = false]) async {
    if (preferCache) {
      try {
        var file = await _cacheManager?.getFileFromCache(url.toString());
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

    error_type? etype;

    try {
      // At first, we try to get the response by fetching it from the web server
      var response = await _httpClient.get(url, headers: {
        "Accept": "application/json",
        if (!kIsWeb)
          "User-Agent":
              "RockItApp (${packageInfo?.packageName ?? 'Unknown'} ${packageInfo?.version ?? 'version unknown'} ${kDebugMode ? 'DEBUG' : 'RELEASE'})",
      });

      debugPrint("Got response for ${url.toString()}: status ${response.statusCode}");

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException("Unexpected status code ${response.statusCode}");
      }

      responseBytes = response.bodyBytes;

      if (!kIsWeb) {
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
        rethrow;
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

        etype = error_type.cachedFallback;
      } catch (ec) {
        throw Exception("Cannot load data from ${url.toString()}: $e.\nCache was also unavailable (reason: $ec)");
      }
    }

    // We need to decode utf8, else text like "äöü" will be decoded wrong
    return ErrorDetails(utf8.decode(responseBytes), etype);
  }
}
