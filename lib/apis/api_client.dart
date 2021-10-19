import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class APIClient {
  static final _httpClient = http.Client();

  Future<String> fetch(Uri url) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    var response = await _httpClient.get(url, headers: {
      "Accept": "application/json",
      "User-Agent":
          "RockItApp (${packageInfo.packageName} ${packageInfo.version} ${kDebugMode ? 'DEBUG' : 'RELEASE'})",
    });

    // We need to decode utf8, else text like "äöü" will be decoded wrong
    return utf8.decode(response.bodyBytes);
  }
}
