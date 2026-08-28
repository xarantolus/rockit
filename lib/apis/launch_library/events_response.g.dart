// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'events_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpaceStation _$SpaceStationFromJson(Map<String, dynamic> json) => SpaceStation(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  description: json['description'] as String?,
  image: ApiImage.fromJsonOrUrl(json['image']),
);

Event _$EventFromJson(Map<String, dynamic> json) => Event(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  slug: json['slug'] as String?,
  type: namedFromJson(json['type']),
  description: json['description'] as String?,
  date: json['date'] == null ? null : DateTime.parse(json['date'] as String),
  datePrecision: json['date_precision'] == null
      ? null
      : DatePrecision.fromJson(json['date_precision'] as Map<String, dynamic>),
  duration: durationFromJson(json['duration']),
  location: json['location'] as String?,
  image: ApiImage.fromJsonOrUrl(Event._readImage(json, 'image')),
  webcastLive: json['webcast_live'] as bool?,
  lastUpdated: json['last_updated'] == null
      ? null
      : DateTime.parse(json['last_updated'] as String),
  agencies:
      (json['agencies'] as List<dynamic>?)
          ?.map((e) => Agency.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  program:
      (json['program'] as List<dynamic>?)
          ?.map((e) => Program.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  launches:
      (json['launches'] as List<dynamic>?)
          ?.map((e) => Launch.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  spacestations:
      (json['spacestations'] as List<dynamic>?)
          ?.map((e) => SpaceStation.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  infoUrls:
      (json['info_urls'] as List<dynamic>?)
          ?.map((e) => ContentUrl.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  vidUrls:
      (json['vid_urls'] as List<dynamic>?)
          ?.map((e) => ContentUrl.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  updates:
      (json['updates'] as List<dynamic>?)
          ?.map((e) => Update.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

UpcomingEventsResponse _$UpcomingEventsResponseFromJson(
  Map<String, dynamic> json,
) => UpcomingEventsResponse(
  count: (json['count'] as num?)?.toInt(),
  next: json['next'] as String?,
  previous: json['previous'] as String?,
  results:
      (json['results'] as List<dynamic>?)
          ?.map((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);
