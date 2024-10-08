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
    return Uri.https('api.spaceflightnewsapi.net', "/v4" + path, query);
  }

  Future<ErrorDetails<List<Article>>> articles([int? _after]) async {
    var query = <String, dynamic>{};

    if (_after != null) {
      query["offset"] = "$_after";
    }

    var uri = _endpoint("/articles/", query);

    var res = await fetchJSON(uri);

    var list = res.data["results"] as List<dynamic>;

    return res.bubble(list.map((e) => Article.fromJson(e)).toList());
  }
}
