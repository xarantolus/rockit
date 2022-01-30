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
      return Uri.https('ll.thespacedevs.com', "/2.2.0" + path, query);
    }
    return Uri.https('lldev.thespacedevs.com', "/2.2.0" + path, query);
  }

  Future<ErrorDetails<UpcomingLaunchesResponse>> upcomingLaunches([String? next]) async {
    var uri = next != null
        ? Uri.parse(next)
        : _endpoint("/launch/upcoming/", {
            "hide_recent_previous": "false",
            "include_suborbital": "true",
            "limit": "50",
            "mode": "detailed",
            "related": "false",
          });

    var res = await fetchJSON(uri);

    return res.bubble(UpcomingLaunchesResponse.fromJson(res.data));
  }

  Future<ErrorDetails<UpcomingEventsResponse>> upcomingEvents([String? next]) async {
    var uri = next != null
        ? Uri.parse(next)
        : _endpoint("/event/upcoming/", {
            "limit": "50",
          });
    var res = await fetchJSON(uri);

    return res.bubble(UpcomingEventsResponse.fromJson(res.data));
  }

  Future<ErrorDetails<Launch>> launch(
    String id, [
    bool preferCache = false,
  ]) async {
    var uri = _endpoint("/launch/" + id, {});

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
