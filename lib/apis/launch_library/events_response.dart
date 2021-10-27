class UpcomingEventsResponse {
  UpcomingEventsResponse({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  final int? count;
  final String? next;
  final String? previous;
  final List<Event>? results;

  factory UpcomingEventsResponse.fromJson(Map<String, dynamic> json) {
    return UpcomingEventsResponse(
      count: json["count"] == null ? null : json["count"],
      next: json["next"] == null ? null : json["next"],
      previous: json["previous"] == null ? null : json["previous"],
      results: json["results"] == null
          ? null
          : List<Event>.from(json["results"].map((x) => Event.fromJson(x))),
    );
  }
}

class Event {
  Event({
    required this.id,
    required this.url,
    required this.slug,
    required this.name,
    required this.updates,
    required this.type,
    required this.description,
    required this.location,
    required this.newsUrl,
    required this.videoUrl,
    required this.featureImage,
    required this.date,
    required this.launches,
    required this.expeditions,
    required this.spacestations,
    required this.program,
  });

  final int id;
  final String? url;
  final String? slug;
  final String? name;
  final List<dynamic>? updates;
  final Type? type;
  final String? description;
  final String? location;
  final String? newsUrl;
  final String? videoUrl;
  final String? featureImage;
  final DateTime? date;
  final List<Launch>? launches;
  final List<Expedition>? expeditions;
  final List<Spacestation>? spacestations;
  final List<Program>? program;

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json["id"] == null ? null : json["id"],
      url: json["url"] == null ? null : json["url"],
      slug: json["slug"] == null ? null : json["slug"],
      name: json["name"] == null ? null : json["name"],
      updates: json["updates"] == null
          ? null
          : List<dynamic>.from(json["updates"].map((x) => x)),
      type: json["type"] == null ? null : Type.fromJson(json["type"]),
      description: json["description"] == null ? null : json["description"],
      location: json["location"] == null ? null : json["location"],
      newsUrl: json["news_url"] == null ? null : json["news_url"],
      videoUrl: json["video_url"] == null ? null : json["video_url"],
      featureImage:
          json["feature_image"] == null ? null : json["feature_image"],
      date: json["date"] == null ? null : DateTime.parse(json["date"]),
      launches: json["launches"] == null
          ? null
          : List<Launch>.from(json["launches"].map((x) => Launch.fromJson(x))),
      expeditions: json["expeditions"] == null
          ? null
          : List<Expedition>.from(
              json["expeditions"].map((x) => Expedition.fromJson(x))),
      spacestations: json["spacestations"] == null
          ? null
          : List<Spacestation>.from(
              json["spacestations"].map((x) => Spacestation.fromJson(x))),
      program: json["program"] == null
          ? null
          : List<Program>.from(json["program"].map((x) => Program.fromJson(x))),
    );
  }
}

class Expedition {
  Expedition({
    required this.id,
    required this.url,
    required this.name,
    required this.start,
    required this.end,
    required this.spacestation,
    required this.missionPatches,
  });

  final int id;
  final String? url;
  final String? name;
  final DateTime? start;
  final DateTime? end;
  final Spacestation? spacestation;
  final List<MissionPatch>? missionPatches;

  factory Expedition.fromJson(Map<String, dynamic> json) {
    return Expedition(
      id: json["id"] == null ? null : json["id"],
      url: json["url"] == null ? null : json["url"],
      name: json["name"] == null ? null : json["name"],
      start: json["start"] == null ? null : DateTime.parse(json["start"]),
      end: json["end"] == null ? null : DateTime.parse(json["end"]),
      spacestation: json["spacestation"] == null
          ? null
          : Spacestation.fromJson(json["spacestation"]),
      missionPatches: json["mission_patches"] == null
          ? null
          : List<MissionPatch>.from(
              json["mission_patches"].map((x) => MissionPatch.fromJson(x))),
    );
  }
}

class MissionPatch {
  MissionPatch({
    required this.id,
    required this.name,
    required this.priority,
    required this.imageUrl,
    required this.agency,
  });

  final int id;
  final String? name;
  final int? priority;
  final String? imageUrl;
  final LaunchServiceProvider? agency;

  factory MissionPatch.fromJson(Map<String, dynamic> json) {
    return MissionPatch(
      id: json["id"] == null ? null : json["id"],
      name: json["name"] == null ? null : json["name"],
      priority: json["priority"] == null ? null : json["priority"],
      imageUrl: json["image_url"] == null ? null : json["image_url"],
      agency: json["agency"] == null
          ? null
          : LaunchServiceProvider.fromJson(json["agency"]),
    );
  }
}

class LaunchServiceProvider {
  LaunchServiceProvider({
    required this.id,
    required this.url,
    required this.name,
    required this.type,
  });

  final int id;
  final String? url;
  final String? name;
  final String? type;

  factory LaunchServiceProvider.fromJson(Map<String, dynamic> json) {
    return LaunchServiceProvider(
      id: json["id"] == null ? null : json["id"],
      url: json["url"] == null ? null : json["url"],
      name: json["name"] == null ? null : json["name"],
      type: json["type"] == null ? null : json["type"],
    );
  }
}

class Spacestation {
  Spacestation({
    required this.id,
    required this.url,
    required this.name,
    required this.status,
    required this.orbit,
    required this.imageUrl,
    required this.founded,
    required this.description,
  });

  final int id;
  final String? url;
  final String? name;
  final Type? status;
  final String? orbit;
  final String? imageUrl;
  final DateTime? founded;
  final String? description;

  factory Spacestation.fromJson(Map<String, dynamic> json) {
    return Spacestation(
      id: json["id"] == null ? null : json["id"],
      url: json["url"] == null ? null : json["url"],
      name: json["name"] == null ? null : json["name"],
      status: json["status"] == null ? null : Type.fromJson(json["status"]),
      orbit: json["orbit"] == null ? null : json["orbit"],
      imageUrl: json["image_url"] == null ? null : json["image_url"],
      founded: json["founded"] == null ? null : DateTime.parse(json["founded"]),
      description: json["description"] == null ? null : json["description"],
    );
  }
}

class Type {
  Type({
    required this.id,
    required this.name,
  });

  final int id;
  final String? name;

  factory Type.fromJson(Map<String, dynamic> json) {
    return Type(
      id: json["id"] == null ? null : json["id"],
      name: json["name"] == null ? null : json["name"],
    );
  }
}

class Launch {
  Launch({
    required this.id,
    required this.url,
    required this.slug,
    required this.name,
    required this.status,
    required this.lastUpdated,
    required this.net,
    required this.windowEnd,
    required this.windowStart,
    required this.probability,
    required this.holdreason,
    required this.failreason,
    required this.hashtag,
    required this.launchServiceProvider,
    required this.rocket,
    required this.mission,
    required this.pad,
    required this.webcastLive,
    required this.image,
    required this.infographic,
    required this.program,
  });

  final String id;
  final String? url;
  final String? slug;
  final String? name;
  final Status? status;
  final DateTime? lastUpdated;
  final DateTime? net;
  final DateTime? windowEnd;
  final DateTime? windowStart;
  final int? probability;
  final String? holdreason;
  final String? failreason;
  final String? hashtag;
  final LaunchServiceProvider? launchServiceProvider;
  final Rocket? rocket;
  final Mission? mission;
  final Pad? pad;
  final bool? webcastLive;
  final String? image;
  final String? infographic;
  final List<Program>? program;

  factory Launch.fromJson(Map<String, dynamic> json) {
    return Launch(
      id: json["id"] == null ? null : json["id"],
      url: json["url"] == null ? null : json["url"],
      slug: json["slug"] == null ? null : json["slug"],
      name: json["name"] == null ? null : json["name"],
      status: json["status"] == null ? null : Status.fromJson(json["status"]),
      lastUpdated: json["last_updated"] == null
          ? null
          : DateTime.parse(json["last_updated"]),
      net: json["net"] == null ? null : DateTime.parse(json["net"]),
      windowEnd: json["window_end"] == null
          ? null
          : DateTime.parse(json["window_end"]),
      windowStart: json["window_start"] == null
          ? null
          : DateTime.parse(json["window_start"]),
      probability: json["probability"] == null ? null : json["probability"],
      holdreason: json["holdreason"] == null ? null : json["holdreason"],
      failreason: json["failreason"] == null ? null : json["failreason"],
      hashtag: json["hashtag"] == null ? null : json["hashtag"],
      launchServiceProvider: json["launch_service_provider"] == null
          ? null
          : LaunchServiceProvider.fromJson(json["launch_service_provider"]),
      rocket: json["rocket"] == null ? null : Rocket.fromJson(json["rocket"]),
      mission:
          json["mission"] == null ? null : Mission.fromJson(json["mission"]),
      pad: json["pad"] == null ? null : Pad.fromJson(json["pad"]),
      webcastLive: json["webcast_live"] == null ? null : json["webcast_live"],
      image: json["image"] == null ? null : json["image"],
      infographic: json["infographic"] == null ? null : json["infographic"],
      program: json["program"] == null
          ? null
          : List<Program>.from(json["program"].map((x) => Program.fromJson(x))),
    );
  }
}

class Mission {
  Mission({
    required this.id,
    required this.name,
    required this.description,
    required this.launchDesignator,
    required this.type,
    required this.orbit,
  });

  final int id;
  final String? name;
  final String? description;
  final dynamic launchDesignator;
  final String? type;
  final Status? orbit;

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json["id"] == null ? null : json["id"],
      name: json["name"] == null ? null : json["name"],
      description: json["description"] == null ? null : json["description"],
      launchDesignator: json["launch_designator"],
      type: json["type"] == null ? null : json["type"],
      orbit: json["orbit"] == null ? null : Status.fromJson(json["orbit"]),
    );
  }
}

class Status {
  Status({
    required this.id,
    required this.name,
    required this.abbrev,
    required this.description,
  });

  final int id;
  final String? name;
  final String? abbrev;
  final String? description;

  factory Status.fromJson(Map<String, dynamic> json) {
    return Status(
      id: json["id"] == null ? null : json["id"],
      name: json["name"] == null ? null : json["name"],
      abbrev: json["abbrev"] == null ? null : json["abbrev"],
      description: json["description"] == null ? null : json["description"],
    );
  }
}

class Pad {
  Pad({
    required this.id,
    required this.url,
    required this.agencyId,
    required this.name,
    required this.infoUrl,
    required this.wikiUrl,
    required this.mapUrl,
    required this.latitude,
    required this.longitude,
    required this.location,
    required this.mapImage,
    required this.totalLaunchCount,
  });

  final int id;
  final String? url;
  final dynamic agencyId;
  final String? name;
  final dynamic infoUrl;
  final String? wikiUrl;
  final String? mapUrl;
  final String? latitude;
  final String? longitude;
  final Location? location;
  final String? mapImage;
  final int? totalLaunchCount;

  factory Pad.fromJson(Map<String, dynamic> json) {
    return Pad(
      id: json["id"] == null ? null : json["id"],
      url: json["url"] == null ? null : json["url"],
      agencyId: json["agency_id"],
      name: json["name"] == null ? null : json["name"],
      infoUrl: json["info_url"],
      wikiUrl: json["wiki_url"] == null ? null : json["wiki_url"],
      mapUrl: json["map_url"] == null ? null : json["map_url"],
      latitude: json["latitude"] == null ? null : json["latitude"],
      longitude: json["longitude"] == null ? null : json["longitude"],
      location:
          json["location"] == null ? null : Location.fromJson(json["location"]),
      mapImage: json["map_image"] == null ? null : json["map_image"],
      totalLaunchCount: json["total_launch_count"] == null
          ? null
          : json["total_launch_count"],
    );
  }
}

class Location {
  Location({
    required this.id,
    required this.url,
    required this.name,
    required this.countryCode,
    required this.mapImage,
    required this.totalLaunchCount,
    required this.totalLandingCount,
  });

  final int id;
  final String? url;
  final String? name;
  final String? countryCode;
  final String? mapImage;
  final int? totalLaunchCount;
  final int? totalLandingCount;

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json["id"] == null ? null : json["id"],
      url: json["url"] == null ? null : json["url"],
      name: json["name"] == null ? null : json["name"],
      countryCode: json["country_code"] == null ? null : json["country_code"],
      mapImage: json["map_image"] == null ? null : json["map_image"],
      totalLaunchCount: json["total_launch_count"] == null
          ? null
          : json["total_launch_count"],
      totalLandingCount: json["total_landing_count"] == null
          ? null
          : json["total_landing_count"],
    );
  }
}

class Program {
  Program({
    required this.id,
    required this.url,
    required this.name,
    required this.description,
    required this.agencies,
    required this.imageUrl,
    required this.startDate,
    required this.endDate,
    required this.infoUrl,
    required this.wikiUrl,
    required this.missionPatches,
  });

  final int id;
  final String? url;
  final String? name;
  final String? description;
  final List<LaunchServiceProvider>? agencies;
  final String? imageUrl;
  final DateTime? startDate;
  final dynamic endDate;
  final String? infoUrl;
  final String? wikiUrl;
  final List<dynamic>? missionPatches;

  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      id: json["id"] == null ? null : json["id"],
      url: json["url"] == null ? null : json["url"],
      name: json["name"] == null ? null : json["name"],
      description: json["description"] == null ? null : json["description"],
      agencies: json["agencies"] == null
          ? null
          : List<LaunchServiceProvider>.from(
              json["agencies"].map((x) => LaunchServiceProvider.fromJson(x))),
      imageUrl: json["image_url"] == null ? null : json["image_url"],
      startDate: json["start_date"] == null
          ? null
          : DateTime.parse(json["start_date"]),
      endDate: json["end_date"],
      infoUrl: json["info_url"] == null ? null : json["info_url"],
      wikiUrl: json["wiki_url"] == null ? null : json["wiki_url"],
      missionPatches: json["mission_patches"] == null
          ? null
          : List<dynamic>.from(json["mission_patches"].map((x) => x)),
    );
  }
}

class Rocket {
  Rocket({
    required this.id,
    required this.configuration,
  });

  final int id;
  final Configuration? configuration;

  factory Rocket.fromJson(Map<String, dynamic> json) {
    return Rocket(
      id: json["id"] == null ? null : json["id"],
      configuration: json["configuration"] == null
          ? null
          : Configuration.fromJson(json["configuration"]),
    );
  }
}

class Configuration {
  Configuration({
    required this.id,
    required this.url,
    required this.name,
    required this.family,
    required this.fullName,
    required this.variant,
  });

  final int id;
  final String? url;
  final String? name;
  final String? family;
  final String? fullName;
  final String? variant;

  factory Configuration.fromJson(Map<String, dynamic> json) {
    return Configuration(
      id: json["id"] == null ? null : json["id"],
      url: json["url"] == null ? null : json["url"],
      name: json["name"] == null ? null : json["name"],
      family: json["family"] == null ? null : json["family"],
      fullName: json["full_name"] == null ? null : json["full_name"],
      variant: json["variant"] == null ? null : json["variant"],
    );
  }
}
