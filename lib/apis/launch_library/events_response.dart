import 'package:json_annotation/json_annotation.dart';

import 'package:rockit/apis/launch_library/iso_duration.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';

export 'package:rockit/apis/launch_library/common.dart';

part 'events_response.g.dart';

/// Launch Library 2.3.0 event models. See common.dart for why every field is
/// nullable.

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class SpaceStation {
  const SpaceStation({this.id, this.name, this.description, this.image});

  final int? id;
  final String? name;
  final String? description;

  @JsonKey(fromJson: ApiImage.fromJsonOrUrl)
  final ApiImage? image;

  factory SpaceStation.fromJson(Map<String, dynamic> json) =>
      _$SpaceStationFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class Event {
  const Event({
    this.id,
    this.name,
    this.slug,
    this.type,
    this.description,
    this.date,
    this.datePrecision,
    this.duration,
    this.location,
    this.image,
    this.newsUrl,
    this.webcastLive,
    this.lastUpdated,
    this.agencies = const [],
    this.program = const [],
    this.launches = const [],
    this.spacestations = const [],
    this.infoUrls = const [],
    this.vidUrls = const [],
    this.updates = const [],
  });

  /// Events are keyed by int, unlike launches which use a uuid string.
  final int? id;

  final String? name;
  final String? slug;

  /// e.g. `Flyby`, `Docking`, `Spacecraft Landing`.
  @JsonKey(fromJson: namedFromJson)
  final String? type;

  final String? description;

  /// Events are *never* known to a time — the coarsest is a whole year — so
  /// this must always be rendered through [datePrecision].
  final DateTime? date;
  final DatePrecision? datePrecision;

  /// How long the event lasts, when it spans a period.
  @JsonKey(fromJson: durationFromJson)
  final Duration? duration;

  /// A free-text place, e.g. `Earth` or `Mercury` — not a launch pad.
  final String? location;

  /// 2.2.0 called this `feature_image` and sent a bare URL.
  @JsonKey(readValue: _readImage, fromJson: ApiImage.fromJsonOrUrl)
  final ApiImage? image;

  final String? newsUrl;
  final bool? webcastLive;
  final DateTime? lastUpdated;

  final List<Agency> agencies;
  final List<Program> program;

  /// Launches this event is tied to, which lets the UI link straight through.
  final List<Launch> launches;

  final List<SpaceStation> spacestations;
  final List<ContentUrl> infoUrls;
  final List<ContentUrl> vidUrls;
  final List<Update> updates;

  static Object? _readImage(Map<dynamic, dynamic> json, String key) =>
      json[key] ?? json['feature_image'];

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class UpcomingEventsResponse {
  const UpcomingEventsResponse({
    this.count,
    this.next,
    this.previous,
    this.results = const [],
  });

  final int? count;
  final String? next;
  final String? previous;
  final List<Event> results;

  factory UpcomingEventsResponse.fromJson(Map<String, dynamic> json) =>
      _$UpcomingEventsResponseFromJson(json);
}
