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

/// An event an article is about.
///
/// `event_id` is a Launch Library 2 id, like [ArticleLaunch.launchId] is.
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class ArticleEvent {
  const ArticleEvent({this.eventId, this.provider});

  final int? eventId;
  final String? provider;

  factory ArticleEvent.fromJson(Map<String, dynamic> json) =>
      _$ArticleEventFromJson(json);
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
    this.events = const [],
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

  /// A third to a half of articles name a launch — but the association is
  /// added *retroactively*, so the newest few hundred have none at all
  /// (0/100 in the last fortnight, 21/100 at three weeks, 45/100 beyond a
  /// month). A fresh feed will therefore usually show no links.
  final List<ArticleLaunch> launches;

  /// Same, for events. Rarer, but these resolve more often when they do
  /// appear: every upcoming event fits in the one cached page.
  final List<ArticleEvent> events;

  /// The Launch Library ids this article is about.
  Iterable<String> get launchIds =>
      launches.map((l) => l.launchId).whereType<String>();

  Iterable<int> get eventIds => events.map((e) => e.eventId).whereType<int>();

  factory Article.fromJson(Map<String, dynamic> json) =>
      _$ArticleFromJson(json);
}
