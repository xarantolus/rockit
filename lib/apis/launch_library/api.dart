import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';

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

  /// How much of the recent past to keep in the listings, so a launch that just
  /// happened does not vanish the moment it lifts off.
  static const recentPastWindow = Duration(days: 1);

  /// The most either listing endpoint will return; asking for more is silently
  /// capped. Worth taking in full — a page is one request either way, and
  /// requests are the scarce resource here, not bytes (100 detailed launches
  /// gzip to ~320 KB against ~175 KB for 50).
  static const pageSize = 100;

  /// The lower bound for a listing query, rounded down to midnight UTC.
  ///
  /// The rounding is not cosmetic. This value goes into the query string, and
  /// the query string *is* the HTTP cache key — an unrounded `now` would
  /// produce a new URL on every call, so the cache would never hit and
  /// cache-first loading would silently stop working. At day granularity the
  /// URL is stable for 24 hours.
  @visibleForTesting
  static DateTime listingCutoff(DateTime now) {
    final utc = now.toUtc().subtract(recentPastWindow);

    return DateTime.utc(utc.year, utc.month, utc.day);
  }

  static String _cutoffParam(DateTime now) {
    // The API wants `2026-08-26T00:00:00Z`.
    return "${listingCutoff(now).toIso8601String().split('.').first}Z";
  }

  Uri _endpoint(String path, Map<String, dynamic> query) {
    query["format"] = "json";

    if (kReleaseMode) {
      return Uri.https('ll.thespacedevs.com', "/2.3.0$path", query);
    }
    return Uri.https('lldev.thespacedevs.com', "/2.3.0$path", query);
  }

  /// Listings use `/launches/` rather than `/launches/upcoming/`: the upcoming
  /// endpoint drops everything in the past, and `hide_recent_previous` became
  /// inert in 2.3.0. Filtering by `net__gte` instead keeps [recentPastWindow]
  /// of just-launched missions in the list.
  ///
  /// `mode=detailed` is deliberate. It is ~32 KB per launch against ~10 KB for
  /// `normal`, but it means opening a launch costs no extra request — and the
  /// API allows only 15 requests an hour, so requests are the scarce resource,
  /// not bytes.
  Uri upcomingLaunchesUri({String? next, DateTime? now}) {
    return next != null
        ? Uri.parse(next)
        : _endpoint("/launches/", {
            "net__gte": _cutoffParam(now ?? DateTime.now()),
            "ordering": "net",
            "include_suborbital": "true",
            "limit": "$pageSize",
            "mode": "detailed",
          });
  }

  Uri upcomingEventsUri({String? next, DateTime? now}) {
    return next != null
        ? Uri.parse(next)
        : _endpoint("/events/", {
            "date__gte": _cutoffParam(now ?? DateTime.now()),
            "ordering": "date",
            "limit": "$pageSize",
            "mode": "detailed",
          });
  }

  Future<ErrorDetails<UpcomingLaunchesResponse>> upcomingLaunches({
    String? next,
    bool preferCache = false,
  }) async {
    var res = await fetchJSON(upcomingLaunchesUri(next: next), preferCache);

    unawaited(_seedDetailCache(res.data, "launches", (r) => r["id"]));

    return res.bubble(
      UpcomingLaunchesResponse.fromJson(APIClient.asJsonObject(res.data)),
    );
  }

  /// The stored page of launches, without touching the network.
  Future<UpcomingLaunchesResponse?> cachedUpcomingLaunches({
    String? next,
  }) async {
    var json = await readCacheJSON(upcomingLaunchesUri(next: next));

    return json == null
        ? null
        : UpcomingLaunchesResponse.fromJson(APIClient.asJsonObject(json));
  }

  Future<ErrorDetails<UpcomingEventsResponse>> upcomingEvents({
    String? next,
    bool preferCache = false,
  }) async {
    var res = await fetchJSON(upcomingEventsUri(next: next), preferCache);

    unawaited(_seedDetailCache(res.data, "events", (r) => r["id"]));

    return res.bubble(
      UpcomingEventsResponse.fromJson(APIClient.asJsonObject(res.data)),
    );
  }

  /// Files every entry of a listing under the URL its own endpoint would use.
  ///
  /// Listings are fetched with `mode=detailed`, so each entry already *is* what
  /// `/launches/<id>/` returns — but the cache is keyed by URL, so nothing was
  /// ever finding it there. Every reader that asks for a single item by id was
  /// paying a request for data it already had: the subscriptions page did it
  /// once per subscription, in turn, on an API that answers in ten seconds and
  /// allows fifteen requests an hour, and the notification deep link did it
  /// too, despite the comment claiming the launch was surely cached.
  ///
  /// Deliberately not awaited by the caller: nothing is waiting on it, and a
  /// listing that renders should not be held up by cache writes.
  Future<void> _seedDetailCache(
    Object? listing,
    String path,
    Object? Function(Map<String, dynamic>) idOf,
  ) async {
    try {
      final results = APIClient.asJsonObject(listing)["results"];
      if (results is! List) {
        return;
      }

      for (final entry in results) {
        if (entry is! Map<String, dynamic>) {
          continue;
        }

        final id = idOf(entry);
        if (id == null) {
          continue;
        }

        await writeCache(_endpoint("/$path/$id/", {}), jsonEncode(entry));
      }
    } catch (err) {
      debugPrint("Could not seed the detail cache from a $path listing: $err");
    }
  }

  /// The stored page of events, without touching the network.
  Future<UpcomingEventsResponse?> cachedUpcomingEvents({String? next}) async {
    var json = await readCacheJSON(upcomingEventsUri(next: next));

    return json == null
        ? null
        : UpcomingEventsResponse.fromJson(APIClient.asJsonObject(json));
  }

  Future<ErrorDetails<Launch>> launch(
    String id, [
    bool preferCache = false,
  ]) async {
    var uri = _endpoint("/launches/$id/", {});

    var res = await fetchJSON(uri, preferCache);

    return res.bubble(Launch.fromJson(APIClient.asJsonObject(res.data)));
  }

  /// The stored launch, without touching the network.
  Future<Launch?> cachedLaunch(String id) async {
    final json = await readCacheJSON(_endpoint("/launches/$id/", {}));

    return json == null ? null : Launch.fromJson(APIClient.asJsonObject(json));
  }

  Future<ErrorDetails<Event>> event(int id, [bool preferCache = false]) async {
    var uri = _endpoint("/events/$id/", {});

    var res = await fetchJSON(uri, preferCache);

    return res.bubble(Event.fromJson(APIClient.asJsonObject(res.data)));
  }
}
