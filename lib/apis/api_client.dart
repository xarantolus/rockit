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
      maxNrOfCacheObjects: 25,
      repo: JsonCacheInfoRepository(databaseName: _key),
      fileService: HttpFileService(),
    ),
  );

  Future<String> fetch(Uri url) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    Uint8List responseBytes;

    var response = await _httpClient.get(url, headers: {
      "Accept": "application/json",
      "User-Agent":
          "RockItApp (${packageInfo.packageName} ${packageInfo.version} ${kDebugMode ? 'DEBUG' : 'RELEASE'})",
    });

    if (response.statusCode == 200) {
      responseBytes = response.bodyBytes;

      await _cacheManager.putFile(url.toString(), responseBytes,
          key: url.toString());
    } else {
      try {
        var file = await _cacheManager.getFileFromCache(url.toString());
        if (file == null) {
          throw Exception();
        }

        responseBytes = await File(file.file.path).readAsBytes();
      } catch (_) {
        throw Exception(
            "Cannot load data from ${url.toString()}: status code ${response.statusCode}. Cache was also unavailable");
      }
    }

    // We need to decode utf8, else text like "äöü" will be decoded wrong
    return utf8.decode(responseBytes);
  }
}
