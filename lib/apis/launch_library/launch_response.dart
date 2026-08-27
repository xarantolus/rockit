import 'package:json_annotation/json_annotation.dart';
import 'package:rockit/apis/launch_library/common.dart';
import 'package:rockit/apis/launch_library/iso_duration.dart';

export 'package:rockit/apis/launch_library/common.dart';

part 'launch_response.g.dart';

/// Launch Library 2.3.0 launch models. See common.dart for why every field is
/// nullable.

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class LaunchStatus {
  const LaunchStatus({this.id, this.name, this.abbrev, this.description});

  final int? id;
  final String? name;
  final String? abbrev;
  final String? description;

  factory LaunchStatus.fromJson(Map<String, dynamic> json) =>
      _$LaunchStatusFromJson(json);

  /// Ids from `/config/launch_statuses/`. An unknown id falls through every
  /// case and the UI renders it neutrally rather than guessing.
  bool get isGo => id == 1;
  bool get isTentative => id == 2 || id == 8; // To Be Determined / Confirmed
  bool get isSuccess => id == 3;
  bool get isFailure => id == 4 || id == 7; // Failure / Partial Failure
  bool get isHold => id == 5;
  bool get isInFlight => id == 6;
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class Location {
  const Location({
    this.id,
    this.name,
    this.timezoneName,
    this.totalLaunchCount,
    this.mapImage,
  });

  final int? id;
  final String? name;

  /// IANA zone of the launch site, e.g. `America/New_York`. Always present in
  /// 2.3.0, and what makes "08:26 local at the pad" possible.
  final String? timezoneName;

  final int? totalLaunchCount;
  final String? mapImage;

  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class Pad {
  const Pad({
    this.id,
    this.name,
    this.description,
    this.latitude,
    this.longitude,
    this.mapUrl,
    this.mapImage,
    this.wikiUrl,
    this.infoUrl,
    this.totalLaunchCount,
    this.country,
    this.location,
  });

  final int? id;
  final String? name;
  final String? description;

  /// Strings in 2.2.0, numbers in 2.3.0 — exactly the kind of type change a
  /// plain cast would throw on.
  @JsonKey(fromJson: doubleFromJson)
  final double? latitude;

  @JsonKey(fromJson: doubleFromJson)
  final double? longitude;

  final String? mapUrl;
  final String? mapImage;
  final String? wikiUrl;
  final String? infoUrl;
  final int? totalLaunchCount;

  /// An object in 2.3.0; 2.2.0 sent `country_code` instead.
  @JsonKey(fromJson: namedFromJson)
  final String? country;

  final Location? location;

  factory Pad.fromJson(Map<String, dynamic> json) => _$PadFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class RocketConfiguration {
  const RocketConfiguration({
    this.id,
    this.name,
    this.fullName,
    this.variant,
    this.description,
    this.manufacturer,
    this.image,
    this.infoUrl,
    this.wikiUrl,
    this.reusable,
    this.length,
    this.diameter,
    this.maxStage,
    this.launchMass,
    this.leoCapacity,
    this.gtoCapacity,
    this.maidenFlight,
    this.successfulLaunches,
    this.failedLaunches,
    this.totalLaunchCount,
  });

  final int? id;
  final String? name;
  final String? fullName;
  final String? variant;
  final String? description;

  final Agency? manufacturer;

  @JsonKey(fromJson: ApiImage.fromJsonOrUrl)
  final ApiImage? image;

  final String? infoUrl;
  final String? wikiUrl;
  final bool? reusable;

  @JsonKey(fromJson: doubleFromJson)
  final double? length;

  @JsonKey(fromJson: doubleFromJson)
  final double? diameter;

  final int? maxStage;
  final int? launchMass;
  final int? leoCapacity;
  final int? gtoCapacity;

  /// A bare `yyyy-MM-dd` rather than a full timestamp.
  final DateTime? maidenFlight;

  final int? successfulLaunches;
  final int? failedLaunches;
  final int? totalLaunchCount;

  factory RocketConfiguration.fromJson(Map<String, dynamic> json) =>
      _$RocketConfigurationFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class LandingLocation {
  const LandingLocation({this.name, this.abbrev});

  final String? name;
  final String? abbrev;

  factory LandingLocation.fromJson(Map<String, dynamic> json) =>
      _$LandingLocationFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class Landing {
  const Landing({
    this.attempt,
    this.success,
    this.description,
    this.downrangeDistance,
    this.type,
    this.landingLocation,
  });

  final bool? attempt;
  final bool? success;
  final String? description;

  /// Kilometres downrange to the landing zone.
  @JsonKey(fromJson: doubleFromJson)
  final double? downrangeDistance;

  @JsonKey(fromJson: namedFromJson)
  final String? type;

  final LandingLocation? landingLocation;

  factory Landing.fromJson(Map<String, dynamic> json) =>
      _$LandingFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class Launcher {
  const Launcher({
    this.id,
    this.serialNumber,
    this.details,
    this.flightProven,
    this.flights,
    this.successfulLandings,
    this.image,
  });

  final int? id;

  /// The airframe, e.g. `B1072`.
  final String? serialNumber;
  final String? details;
  final bool? flightProven;

  /// Total flights for this airframe, across all missions.
  final int? flights;
  final int? successfulLandings;

  @JsonKey(fromJson: ApiImage.fromJsonOrUrl)
  final ApiImage? image;

  factory Launcher.fromJson(Map<String, dynamic> json) =>
      _$LauncherFromJson(json);
}

/// One booster on this flight, carrying the reuse story the app never showed:
/// which airframe, how many times it has flown, how fast it was turned around,
/// and whether it is landing.
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class LauncherStage {
  const LauncherStage({
    this.id,
    this.type,
    this.reused,
    this.launcherFlightNumber,
    this.turnAroundTime,
    this.previousFlightDate,
    this.launcher,
    this.landing,
  });

  final int? id;
  final String? type;
  final bool? reused;

  /// Which flight of this particular airframe this is.
  final int? launcherFlightNumber;

  /// How long this airframe sat between flights. Sent as an ISO-8601 duration
  /// in 2.3.0 (`P27DT4H`) and as whole days in 2.2.0; both become a [Duration].
  @JsonKey(readValue: _readTurnAround, fromJson: durationFromJson)
  final Duration? turnAroundTime;

  final DateTime? previousFlightDate;
  final Launcher? launcher;
  final Landing? landing;

  static Object? _readTurnAround(Map<dynamic, dynamic> json, String key) {
    final value = json[key];
    if (value != null) return value;

    final days = json['turn_around_time_days'];
    return days is num ? 'P${days.toInt()}D' : null;
  }

  factory LauncherStage.fromJson(Map<String, dynamic> json) =>
      _$LauncherStageFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class SpacecraftStage {
  const SpacecraftStage({this.id, this.name, this.description, this.image});

  final int? id;
  final String? name;
  final String? description;

  @JsonKey(fromJson: ApiImage.fromJsonOrUrl)
  final ApiImage? image;

  factory SpacecraftStage.fromJson(Map<String, dynamic> json) =>
      _$SpacecraftStageFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class Rocket {
  const Rocket({
    this.id,
    this.configuration,
    this.launcherStage = const [],
    this.spacecraftStage = const [],
  });

  final int? id;
  final RocketConfiguration? configuration;
  final List<LauncherStage> launcherStage;

  /// A single object in 2.2.0, a list in 2.3.0 — a crewed flight can carry
  /// more than one spacecraft.
  final List<SpacecraftStage> spacecraftStage;

  factory Rocket.fromJson(Map<String, dynamic> json) => _$RocketFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class Mission {
  const Mission({
    this.id,
    this.name,
    this.type,
    this.description,
    this.orbit,
    this.agencies = const [],
  });

  final int? id;
  final String? name;

  /// e.g. `Earth Science`, `Astrophysics`.
  final String? type;
  final String? description;
  final Orbit? orbit;
  final List<Agency> agencies;

  factory Mission.fromJson(Map<String, dynamic> json) =>
      _$MissionFromJson(json);
}

/// One milestone in the countdown, e.g. ignition at `-PT7S`. Only about one
/// launch in eight has any, so this is a bonus section, never a headline.
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class TimelineEvent {
  const TimelineEvent({this.relativeTime, this.type, this.description});

  /// Offset from T-0, negative before liftoff.
  @JsonKey(fromJson: durationFromJson)
  final Duration? relativeTime;

  @JsonKey(readValue: _readTypeName)
  final String? type;

  @JsonKey(readValue: _readTypeDescription)
  final String? description;

  static Object? _readTypeName(Map<dynamic, dynamic> json, String key) {
    final type = json['type'];
    if (type is Map) return type['abbrev'] ?? type['name'];
    return null;
  }

  static Object? _readTypeDescription(Map<dynamic, dynamic> json, String key) {
    final type = json['type'];
    return type is Map ? type['description'] : null;
  }

  factory TimelineEvent.fromJson(Map<String, dynamic> json) =>
      _$TimelineEventFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class Launch {
  const Launch({
    this.id,
    this.name,
    this.slug,
    this.net,
    this.netPrecision,
    this.windowStart,
    this.windowEnd,
    this.lastUpdated,
    this.status,
    this.image,
    this.probability,
    this.weatherConcerns,
    this.failreason,
    this.hashtag,
    this.webcastLive,
    this.launchServiceProvider,
    this.rocket,
    this.mission,
    this.pad,
    this.padTurnaround,
    this.program = const [],
    this.missionPatches = const [],
    this.infoUrls = const [],
    this.vidUrls = const [],
    this.updates = const [],
    this.timeline = const [],
    this.orbitalLaunchAttemptCount,
    this.agencyLaunchAttemptCount,
    this.agencyLaunchAttemptCountYear,
    this.padLaunchAttemptCount,
  });

  final String? id;
  final String? name;
  final String? slug;

  /// No Earlier Than — the headline time, only as precise as [netPrecision].
  final DateTime? net;
  final DatePrecision? netPrecision;

  final DateTime? windowStart;
  final DateTime? windowEnd;
  final DateTime? lastUpdated;
  final LaunchStatus? status;

  @JsonKey(fromJson: ApiImage.fromJsonOrUrl)
  final ApiImage? image;

  /// Percentage chance of favourable weather; null until close to launch.
  @JsonKey(fromJson: intFromJson)
  final int? probability;

  final String? weatherConcerns;
  final String? failreason;
  final String? hashtag;
  final bool? webcastLive;

  final Agency? launchServiceProvider;
  final Rocket? rocket;
  final Mission? mission;
  final Pad? pad;

  /// Time since the previous launch from this pad.
  @JsonKey(fromJson: durationFromJson)
  final Duration? padTurnaround;

  final List<Program> program;
  final List<MissionPatch> missionPatches;

  /// 2.2.0 spelled these `infoURLs` / `vidURLs`.
  @JsonKey(readValue: _readInfoUrls)
  final List<ContentUrl> infoUrls;

  @JsonKey(readValue: _readVidUrls)
  final List<ContentUrl> vidUrls;

  final List<Update> updates;
  final List<TimelineEvent> timeline;

  final int? orbitalLaunchAttemptCount;

  /// All-time launch count for this provider.
  final int? agencyLaunchAttemptCount;

  /// Count within the current year — a different, much smaller number, and the
  /// one that belongs in a "this year" sentence.
  final int? agencyLaunchAttemptCountYear;

  /// All-time launch count from this pad.
  final int? padLaunchAttemptCount;

  static Object? _readInfoUrls(Map<dynamic, dynamic> json, String key) =>
      json[key] ?? json['infoURLs'];

  static Object? _readVidUrls(Map<dynamic, dynamic> json, String key) =>
      json[key] ?? json['vidURLs'];

  /// Best available human name for the rocket.
  String? get rocketName =>
      rocket?.configuration?.fullName ?? rocket?.configuration?.name;

  /// Who is flying it — the card subtitle.
  String? get providerName =>
      launchServiceProvider?.name ?? launchServiceProvider?.abbrev;

  factory Launch.fromJson(Map<String, dynamic> json) => _$LaunchFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class UpcomingLaunchesResponse {
  const UpcomingLaunchesResponse({
    this.count,
    this.next,
    this.previous,
    this.results = const [],
  });

  final int? count;
  final String? next;
  final String? previous;
  final List<Launch> results;

  factory UpcomingLaunchesResponse.fromJson(Map<String, dynamic> json) =>
      _$UpcomingLaunchesResponseFromJson(json);
}
