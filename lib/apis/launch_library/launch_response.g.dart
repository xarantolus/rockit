// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'launch_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LaunchStatus _$LaunchStatusFromJson(Map<String, dynamic> json) => LaunchStatus(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  abbrev: json['abbrev'] as String?,
  description: json['description'] as String?,
);

Location _$LocationFromJson(Map<String, dynamic> json) => Location(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  timezoneName: json['timezone_name'] as String?,
  totalLaunchCount: (json['total_launch_count'] as num?)?.toInt(),
  mapImage: json['map_image'] as String?,
);

Pad _$PadFromJson(Map<String, dynamic> json) => Pad(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  description: json['description'] as String?,
  latitude: doubleFromJson(json['latitude']),
  longitude: doubleFromJson(json['longitude']),
  mapUrl: json['map_url'] as String?,
  mapImage: json['map_image'] as String?,
  wikiUrl: json['wiki_url'] as String?,
  infoUrl: json['info_url'] as String?,
  totalLaunchCount: (json['total_launch_count'] as num?)?.toInt(),
  country: namedFromJson(json['country']),
  location: json['location'] == null
      ? null
      : Location.fromJson(json['location'] as Map<String, dynamic>),
);

RocketConfiguration _$RocketConfigurationFromJson(Map<String, dynamic> json) =>
    RocketConfiguration(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      fullName: json['full_name'] as String?,
      variant: json['variant'] as String?,
      description: json['description'] as String?,
      manufacturer: json['manufacturer'] == null
          ? null
          : Agency.fromJson(json['manufacturer'] as Map<String, dynamic>),
      image: ApiImage.fromJsonOrNull(json['image']),
      infoUrl: json['info_url'] as String?,
      wikiUrl: json['wiki_url'] as String?,
      reusable: json['reusable'] as bool?,
      length: doubleFromJson(json['length']),
      diameter: doubleFromJson(json['diameter']),
      maxStage: (json['max_stage'] as num?)?.toInt(),
      launchMass: (json['launch_mass'] as num?)?.toInt(),
      leoCapacity: (json['leo_capacity'] as num?)?.toInt(),
      gtoCapacity: (json['gto_capacity'] as num?)?.toInt(),
      maidenFlight: json['maiden_flight'] == null
          ? null
          : DateTime.parse(json['maiden_flight'] as String),
      successfulLaunches: (json['successful_launches'] as num?)?.toInt(),
      failedLaunches: (json['failed_launches'] as num?)?.toInt(),
      totalLaunchCount: (json['total_launch_count'] as num?)?.toInt(),
    );

LandingLocation _$LandingLocationFromJson(Map<String, dynamic> json) =>
    LandingLocation(
      name: json['name'] as String?,
      abbrev: json['abbrev'] as String?,
    );

Landing _$LandingFromJson(Map<String, dynamic> json) => Landing(
  attempt: json['attempt'] as bool?,
  success: json['success'] as bool?,
  description: json['description'] as String?,
  downrangeDistance: doubleFromJson(json['downrange_distance']),
  type: namedFromJson(json['type']),
  landingLocation: json['landing_location'] == null
      ? null
      : LandingLocation.fromJson(
          json['landing_location'] as Map<String, dynamic>,
        ),
);

Launcher _$LauncherFromJson(Map<String, dynamic> json) => Launcher(
  id: (json['id'] as num?)?.toInt(),
  serialNumber: json['serial_number'] as String?,
  details: json['details'] as String?,
  flightProven: json['flight_proven'] as bool?,
  flights: (json['flights'] as num?)?.toInt(),
  successfulLandings: (json['successful_landings'] as num?)?.toInt(),
  image: ApiImage.fromJsonOrNull(json['image']),
);

LauncherStage _$LauncherStageFromJson(Map<String, dynamic> json) =>
    LauncherStage(
      id: (json['id'] as num?)?.toInt(),
      type: json['type'] as String?,
      reused: json['reused'] as bool?,
      launcherFlightNumber: (json['launcher_flight_number'] as num?)?.toInt(),
      turnAroundTime: durationFromJson(json['turn_around_time']),
      previousFlightDate: json['previous_flight_date'] == null
          ? null
          : DateTime.parse(json['previous_flight_date'] as String),
      launcher: json['launcher'] == null
          ? null
          : Launcher.fromJson(json['launcher'] as Map<String, dynamic>),
      landing: json['landing'] == null
          ? null
          : Landing.fromJson(json['landing'] as Map<String, dynamic>),
    );

SpacecraftStage _$SpacecraftStageFromJson(Map<String, dynamic> json) =>
    SpacecraftStage(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      description: json['description'] as String?,
      image: ApiImage.fromJsonOrNull(json['image']),
    );

Rocket _$RocketFromJson(Map<String, dynamic> json) => Rocket(
  id: (json['id'] as num?)?.toInt(),
  configuration: json['configuration'] == null
      ? null
      : RocketConfiguration.fromJson(
          json['configuration'] as Map<String, dynamic>,
        ),
  launcherStage:
      (json['launcher_stage'] as List<dynamic>?)
          ?.map((e) => LauncherStage.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  spacecraftStage:
      (json['spacecraft_stage'] as List<dynamic>?)
          ?.map((e) => SpacecraftStage.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Mission _$MissionFromJson(Map<String, dynamic> json) => Mission(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  type: json['type'] as String?,
  description: json['description'] as String?,
  orbit: json['orbit'] == null
      ? null
      : Orbit.fromJson(json['orbit'] as Map<String, dynamic>),
  agencies:
      (json['agencies'] as List<dynamic>?)
          ?.map((e) => Agency.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

TimelineEvent _$TimelineEventFromJson(Map<String, dynamic> json) =>
    TimelineEvent(
      relativeTime: durationFromJson(json['relative_time']),
      type: TimelineEvent._readTypeName(json, 'type') as String?,
      description:
          TimelineEvent._readTypeDescription(json, 'description') as String?,
    );

Launch _$LaunchFromJson(Map<String, dynamic> json) => Launch(
  id: json['id'] as String?,
  name: json['name'] as String?,
  slug: json['slug'] as String?,
  net: json['net'] == null ? null : DateTime.parse(json['net'] as String),
  netPrecision: json['net_precision'] == null
      ? null
      : DatePrecision.fromJson(json['net_precision'] as Map<String, dynamic>),
  windowStart: json['window_start'] == null
      ? null
      : DateTime.parse(json['window_start'] as String),
  windowEnd: json['window_end'] == null
      ? null
      : DateTime.parse(json['window_end'] as String),
  lastUpdated: json['last_updated'] == null
      ? null
      : DateTime.parse(json['last_updated'] as String),
  status: json['status'] == null
      ? null
      : LaunchStatus.fromJson(json['status'] as Map<String, dynamic>),
  image: ApiImage.fromJsonOrNull(json['image']),
  probability: intFromJson(json['probability']),
  weatherConcerns: json['weather_concerns'] as String?,
  failreason: json['failreason'] as String?,
  hashtag: json['hashtag'] as String?,
  webcastLive: json['webcast_live'] as bool?,
  launchServiceProvider: json['launch_service_provider'] == null
      ? null
      : Agency.fromJson(
          json['launch_service_provider'] as Map<String, dynamic>,
        ),
  rocket: json['rocket'] == null
      ? null
      : Rocket.fromJson(json['rocket'] as Map<String, dynamic>),
  mission: json['mission'] == null
      ? null
      : Mission.fromJson(json['mission'] as Map<String, dynamic>),
  pad: json['pad'] == null
      ? null
      : Pad.fromJson(json['pad'] as Map<String, dynamic>),
  padTurnaround: durationFromJson(json['pad_turnaround']),
  program:
      (json['program'] as List<dynamic>?)
          ?.map((e) => Program.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  missionPatches:
      (json['mission_patches'] as List<dynamic>?)
          ?.map((e) => MissionPatch.fromJson(e as Map<String, dynamic>))
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
  timeline:
      (json['timeline'] as List<dynamic>?)
          ?.map((e) => TimelineEvent.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  orbitalLaunchAttemptCount: (json['orbital_launch_attempt_count'] as num?)
      ?.toInt(),
  agencyLaunchAttemptCount: (json['agency_launch_attempt_count'] as num?)
      ?.toInt(),
  agencyLaunchAttemptCountYear:
      (json['agency_launch_attempt_count_year'] as num?)?.toInt(),
  padLaunchAttemptCount: (json['pad_launch_attempt_count'] as num?)?.toInt(),
);

UpcomingLaunchesResponse _$UpcomingLaunchesResponseFromJson(
  Map<String, dynamic> json,
) => UpcomingLaunchesResponse(
  count: (json['count'] as num?)?.toInt(),
  next: json['next'] as String?,
  previous: json['previous'] as String?,
  results:
      (json['results'] as List<dynamic>?)
          ?.map((e) => Launch.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);
