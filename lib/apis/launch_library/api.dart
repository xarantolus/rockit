import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:rockit/apis/api_client.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/apis/launch_library/upcoming_response.dart';

class LaunchLibraryAPI extends APIClient {
  // Singleton: the LaunchLibraryAPI "constructor" always returns the same object
  static final instance = LaunchLibraryAPI._internal();
  factory LaunchLibraryAPI() {
    return instance;
  }

  // Actual, private constructor
  LaunchLibraryAPI._internal();

  Uri _endpoint(String path, Map<String, dynamic> query) {
    query["format"] = "json";

    if (kReleaseMode) {
      return Uri.https('ll.thespacedevs.com', "/2.2.0" + path, query);
    }
    return Uri.https('lldev.thespacedevs.com', "/2.2.0" + path, query);
  }

  Future<UpcomingResponse> upcomingLaunches([String? next]) async {
    var uri = next != null
        ? Uri.parse(next)
        : _endpoint("/launch/upcoming/", {
            "hide_recent_previous": "false",
            "include_suborbital": "true",
            "limit": "25",
            "mode": "detailed",
            "related": "false",
          });

    return UpcomingResponse.fromJson(await fetchJSON(uri));
  }

  Future<UpcomingEventsResponse> upcomingEvents([String? next]) async {
    var uri = next != null
        ? Uri.parse(next)
        : _endpoint("/event/upcoming/", {
            "limit": "25",
          });

    return UpcomingEventsResponse.fromJson(await fetchJSON(uri));
  }

  Future<Launch> launch(String id) async {
    var uri = _endpoint("/launch/" + id, {});

    var decoded = jsonDecode(await fetch(uri));

    return Launch.fromJson(decoded);
  }

  Future<Event> event(int id) async {
    var uri = _endpoint("/event/$id", {});

    return Event.fromJson(await fetchJSON(uri));
  }
}
