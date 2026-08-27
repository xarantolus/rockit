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

  Uri articlesUri([int? after]) {
    var query = <String, dynamic>{};

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
}
