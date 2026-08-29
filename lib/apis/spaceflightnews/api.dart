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

  Uri searchArticlesUri(String query, [int? after]) {
    final params = <String, dynamic>{
      "limit": "$pageSize",
      "search": query,
      if (after != null) "offset": "$after",
    };

    return _endpoint("/articles/", params);
  }

  /// Full-text search over titles and summaries.
  ///
  /// Server-side, unlike the launches and events search: this API has no
  /// advertised rate limit and answered twenty-five rapid requests without
  /// complaint, so a query per keystroke pause is affordable here.
  Future<ErrorDetails<List<Article>>> searchArticles(
    String query, {
    int? after,
  }) async {
    var res = await fetchJSON(searchArticlesUri(query, after));

    return res.bubble(parseArticles(res.data));
  }

  /// The stored page of articles, without touching the network.
  Future<List<Article>?> cachedArticles([int? after]) async {
    var json = await readCacheJSON(articlesUri(after));

    return json == null ? null : parseArticles(json);
  }
}
