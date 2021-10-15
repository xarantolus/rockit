import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:rockit/launch_library/json_convert.dart';

class LaunchLibraryAPI {
  // Singleton: the LaunchLibraryAPI "constructor" always returns the same object
  static final instance = LaunchLibraryAPI._internal();
  factory LaunchLibraryAPI() {
    return instance;
  }

  final _httpClient = http.Client();

  // Actual, private constructor
  LaunchLibraryAPI._internal();

  Uri _endpoint(String path, Map<String, dynamic> query) {
    query["format"] = "json";

    if (kReleaseMode) {
      Uri.https('ll.thespacedevs.com', "/2.2.0" + path, query);
    }
    return Uri.https('lldev.thespacedevs.com', "/2.2.0" + path, query);
  }

  Future<String> _fetch(Uri url) async {
    var response = await _httpClient.get(url);

    return response.body;
  }

  Future<UpcomingResponse> upcomingLaunches([String? next]) async {
    var uri = next != null
        ? Uri.parse(next)
        : _endpoint("/launch/upcoming/", <String, dynamic>{
            "hide_recent_previous": "false",
            "include_suborbital": "true",
            "limit": "25",
            "mode": "detailed",
            "related": "false",
          });

    var decoded = jsonDecode(await _fetch(uri));

    return UpcomingResponse.fromJson(decoded);
  }
}
