// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArticleLaunch _$ArticleLaunchFromJson(Map<String, dynamic> json) =>
    ArticleLaunch(
      launchId: json['launch_id'] as String?,
      provider: json['provider'] as String?,
    );

ArticleEvent _$ArticleEventFromJson(Map<String, dynamic> json) => ArticleEvent(
  eventId: (json['event_id'] as num?)?.toInt(),
  provider: json['provider'] as String?,
);

Article _$ArticleFromJson(Map<String, dynamic> json) => Article(
  id: (json['id'] as num?)?.toInt(),
  title: json['title'] as String?,
  url: json['url'] as String?,
  imageUrl: json['image_url'] as String?,
  newsSite: json['news_site'] as String?,
  summary: json['summary'] as String?,
  publishedAt: json['published_at'] == null
      ? null
      : DateTime.parse(json['published_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  featured: json['featured'] as bool?,
  launches:
      (json['launches'] as List<dynamic>?)
          ?.map((e) => ArticleLaunch.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  events:
      (json['events'] as List<dynamic>?)
          ?.map((e) => ArticleEvent.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);
