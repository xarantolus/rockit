import 'package:flutter/foundation.dart';

import 'package:rockit/apis/api_client.dart';
import 'package:rockit/apis/error_details.dart';
import 'package:rockit/apis/spaceflightnews/article_response.dart';

class SpaceFlightNewsAPI extends APIClient {
  // Singleton: the LaunchLibraryAPI "constructor" always returns the same object
  static final instance = SpaceFlightNewsAPI._internal();
  factory SpaceFlightNewsAPI() {
    return instance;
  }

  // Actual, private constructor
  SpaceFlightNewsAPI._internal();

  Uri _endpoint(String path, Map<String, dynamic> query) {
    return Uri.https('api.spaceflightnewsapi.net', "/v4$path", query);
  }

  /// The API pages ten at a time by default, which is barely a screen and a
  /// half. This one is fast and has no request budget to protect — unlike the
  /// Launch Library's fifteen an hour — so take a real page at a time.
  static const pageSize = 25;

  Uri articlesUri([int? after]) {
    var query = <String, dynamic>{"limit": "$pageSize"};

    if (after != null) {
      query["offset"] = "$after";
    }

    return _endpoint("/articles/", query);
  }

  static List<Article> parseArticles(dynamic json) {
    var list = json["results"] as List<dynamic>;

    return list.map((e) => Article.fromJson(e)).toList();
  }

  Future<ErrorDetails<List<Article>>> articles([int? after]) async {
    var res = await fetchJSON(articlesUri(after));

    return res.bubble(parseArticles(res.data));
  }

  /// The stored page of articles, without touching the network.
  Future<List<Article>?> cachedArticles([int? after]) async {
    var json = await readCacheJSON(articlesUri(after));

    return json == null ? null : parseArticles(json);
  }

  /// Fetches the first page purely to fill the HTTP cache.
  ///
  /// The news tab is the third one, so its page is not built — and does not
  /// start loading — until the user swipes to it. Warming the cache at startup
  /// means it has something to show the moment it opens. Errors are swallowed:
  /// nothing is waiting on this, and the tab retries on its own.
  Future<void> prefetchArticles() async {
    try {
      await articles();
    } catch (e) {
      debugPrint("Could not prefetch articles: $e");
    }
  }
}
