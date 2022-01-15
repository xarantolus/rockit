import 'upcoming_response.dart';

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
      count: json["count"],
      next: json["next"],
      previous: json["previous"],
      results: json["results"] == null ? null : List<Event>.from(json["results"].map((x) => Event.fromJson(x))),
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
  final List<Update>? updates;
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
      id: json["id"],
      url: json["url"],
      slug: json["slug"],
      name: json["name"],
      updates: json["updates"] == null ? null : (json["updates"] as List).map((e) => Update.fromJson(e)).toList(),
      type: json["type"] == null ? null : Type.fromJson(json["type"]),
      description: json["description"],
      location: json["location"],
      newsUrl: json["news_url"],
      videoUrl: json["video_url"],
      featureImage: json["feature_image"],
      date: json["date"] == null ? null : DateTime.parse(json["date"]),
      launches: json["launches"] == null ? null : List<Launch>.from(json["launches"].map((x) => Launch.fromJson(x))),
      expeditions: json["expeditions"] == null
          ? null
          : List<Expedition>.from(json["expeditions"].map((x) => Expedition.fromJson(x))),
      spacestations: json["spacestations"] == null
          ? null
          : List<Spacestation>.from(json["spacestations"].map((x) => Spacestation.fromJson(x))),
      program: json["program"] == null ? null : List<Program>.from(json["program"].map((x) => Program.fromJson(x))),
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
      id: json["id"],
      url: json["url"],
      name: json["name"],
      start: json["start"] == null ? null : DateTime.parse(json["start"]),
      end: json["end"] == null ? null : DateTime.parse(json["end"]),
      spacestation: json["spacestation"] == null ? null : Spacestation.fromJson(json["spacestation"]),
      missionPatches: json["mission_patches"] == null
          ? null
          : List<MissionPatch>.from(json["mission_patches"].map((x) => MissionPatch.fromJson(x))),
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
      id: json["id"],
      name: json["name"],
      priority: json["priority"],
      imageUrl: json["image_url"],
      agency: json["agency"] == null ? null : LaunchServiceProvider.fromJson(json["agency"]),
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
      id: json["id"],
      url: json["url"],
      name: json["name"],
      type: json["type"],
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
      id: json["id"],
      url: json["url"],
      name: json["name"],
      status: json["status"] == null ? null : Type.fromJson(json["status"]),
      orbit: json["orbit"],
      imageUrl: json["image_url"],
      founded: json["founded"] == null ? null : DateTime.parse(json["founded"]),
      description: json["description"],
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
      id: json["id"],
      name: json["name"],
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
      id: json["id"],
      url: json["url"],
      name: json["name"],
      countryCode: json["country_code"],
      mapImage: json["map_image"],
      totalLaunchCount: json["total_launch_count"],
      totalLandingCount: json["total_landing_count"],
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
      id: json["id"],
      url: json["url"],
      name: json["name"],
      description: json["description"],
      agencies: json["agencies"] == null
          ? null
          : List<LaunchServiceProvider>.from(json["agencies"].map((x) => LaunchServiceProvider.fromJson(x))),
      imageUrl: json["image_url"],
      startDate: json["start_date"] == null ? null : DateTime.parse(json["start_date"]),
      endDate: json["end_date"],
      infoUrl: json["info_url"],
      wikiUrl: json["wiki_url"],
      missionPatches:
          json["mission_patches"] == null ? null : List<dynamic>.from(json["mission_patches"].map((x) => x)),
    );
  }
}
