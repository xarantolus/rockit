import 'package:json_annotation/json_annotation.dart';

part 'article_response.g.dart';

/// A launch an article is about.
///
/// `launch_id` is a Launch Library 2 uuid — the same identifier our launch
/// models use — so an article can be linked straight through to its launch.
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class ArticleLaunch {
  const ArticleLaunch({this.launchId, this.provider});

  final String? launchId;
  final String? provider;

  factory ArticleLaunch.fromJson(Map<String, dynamic> json) =>
      _$ArticleLaunchFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class Article {
  const Article({
    this.id,
    this.title,
    this.url,
    this.imageUrl,
    this.newsSite,
    this.summary,
    this.publishedAt,
    this.updatedAt,
    this.featured,
    this.launches = const [],
  });

  final int? id;
  final String? title;
  final String? url;
  final String? imageUrl;
  final String? newsSite;
  final String? summary;
  final DateTime? publishedAt;
  final DateTime? updatedAt;
  final bool? featured;

  /// About a third of articles name a launch; the rest are empty.
  final List<ArticleLaunch> launches;

  /// The Launch Library ids this article is about.
  Iterable<String> get launchIds =>
      launches.map((l) => l.launchId).whereType<String>();

  factory Article.fromJson(Map<String, dynamic> json) =>
      _$ArticleFromJson(json);
}
