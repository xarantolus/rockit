import 'package:flutter/foundation.dart';
import 'package:rockit/apis/api_client.dart';
import 'package:rockit/apis/error_details.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';

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
      return Uri.https('ll.thespacedevs.com', "/2.2.0$path", query);
    }
    return Uri.https('lldev.thespacedevs.com', "/2.2.0$path", query);
  }

  Uri upcomingLaunchesUri({String? next}) {
    return next != null
        ? Uri.parse(next)
        : _endpoint("/launch/upcoming/", {
            "hide_recent_previous": "false",
            "include_suborbital": "true",
            "limit": "50",
            "mode": "detailed",
            "related": "false",
          });
  }

  Uri upcomingEventsUri({String? next}) {
    return next != null
        ? Uri.parse(next)
        : _endpoint("/event/upcoming/", {
            "limit": "50",
          });
  }

  Future<ErrorDetails<UpcomingLaunchesResponse>> upcomingLaunches({
    String? next,
    bool preferCache = false,
  }) async {
    var res = await fetchJSON(upcomingLaunchesUri(next: next), preferCache);

    return res.bubble(UpcomingLaunchesResponse.fromJson(res.data));
  }

  /// The stored page of upcoming launches, without touching the network.
  Future<UpcomingLaunchesResponse?> cachedUpcomingLaunches({
    String? next,
  }) async {
    var json = await readCacheJSON(upcomingLaunchesUri(next: next));

    return json == null ? null : UpcomingLaunchesResponse.fromJson(json);
  }

  Future<ErrorDetails<UpcomingEventsResponse>> upcomingEvents({
    String? next,
    bool preferCache = false,
  }) async {
    var res = await fetchJSON(upcomingEventsUri(next: next), preferCache);

    return res.bubble(UpcomingEventsResponse.fromJson(res.data));
  }

  /// The stored page of upcoming events, without touching the network.
  Future<UpcomingEventsResponse?> cachedUpcomingEvents({
    String? next,
  }) async {
    var json = await readCacheJSON(upcomingEventsUri(next: next));

    return json == null ? null : UpcomingEventsResponse.fromJson(json);
  }

  Future<ErrorDetails<Launch>> launch(
    String id, [
    bool preferCache = false,
  ]) async {
    var uri = _endpoint("/launch/$id", {});

    var res = await fetchJSON(uri, preferCache);

    return res.bubble(Launch.fromJson(res.data));
  }

  // the id given should be either a String or int
  Future<ErrorDetails<Event>> event(
    dynamic id, [
    bool preferCache = false,
  ]) async {
    var uri = _endpoint("/event/$id", {});

    var res = await fetchJSON(uri, preferCache);

    return res.bubble(Event.fromJson(res.data));
  }
}
