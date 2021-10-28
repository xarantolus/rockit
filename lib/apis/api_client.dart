import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';

class APIClient {
  static final _httpClient = http.Client();

  static const _key = 'http-cache';

  static final _cacheManager = CacheManager(
    Config(
      _key,
      stalePeriod: const Duration(days: 3),
      repo: JsonCacheInfoRepository(databaseName: _key),
      fileService: HttpFileService(),
    ),
  );

  Future<String> fetch(Uri url) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    Uint8List responseBytes;

    if (kDebugMode) {
      debugPrint("Fetching URL ${url.toString()}");
    }

    try {
      // At first, we try to get the response by fetching it from the web server
      var response = await _httpClient.get(url, headers: {
        "Accept": "application/json",
        "User-Agent":
            "RockItApp (${packageInfo.packageName} ${packageInfo.version} ${kDebugMode ? 'DEBUG' : 'RELEASE'})",
      });

      if (kDebugMode) {
        debugPrint(
            "Got response for ${url.toString()}: status ${response.statusCode}");
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException("Unexpected status code ${response.statusCode}");
      }

      responseBytes = response.bodyBytes;

      // If everything worked, we can put the file into the cache. That way, we can
      // access it in case of no internet or a rate limit
      await _cacheManager.putFile(
        url.toString(),
        responseBytes,
        key: url.toString(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error fetching ${url.toString()}: $e");
      }

      // We likely have no internet, or we have hit a rate limit
      try {
        // Now we can try to get this content from the cache.
        var file = await _cacheManager.getFileFromCache(url.toString());
        if (file == null) {
          throw Exception("This URL hasn't been cached before");
        }

        responseBytes = await File(file.file.path).readAsBytes();
      } catch (ec) {
        throw Exception(
            "Cannot load data from ${url.toString()}: $e.\nCache was also unavailable (reason: $ec)");
      }
    }

    // We need to decode utf8, else text like "äöü" will be decoded wrong
    return utf8.decode(responseBytes);
  }
}
