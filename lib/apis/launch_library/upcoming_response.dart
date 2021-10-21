class UpcomingResponse {
  int? count;
  String? next;
  String? previous;
  List<Launch>? results;

  UpcomingResponse({count, next, previous, results});

  UpcomingResponse.fromJson(Map<String, dynamic> json) {
    count = json["count"];
    next = json["next"];
    previous = json["previous"];
    results = json["results"] == null
        ? null
        : (json["results"] as List).map((e) => Launch.fromJson(e)).toList();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["count"] = count;
    data["next"] = next;
    data["previous"] = previous;
    if (results != null) {
      data["results"] = results?.map((e) => e.toJson()).toList();
    }
    return data;
  }
}

class Launch {
  String? id;
  String? url;
  String? slug;
  String? flightclubUrl;
  dynamic? rSpacexApiId;
  String? name;
  Status? status;
  String? lastUpdated;
  List<Update>? updates;
  String? net;
  String? windowEnd;
  String? windowStart;
  dynamic? probability;
  String? holdreason;
  String? failreason;
  dynamic? hashtag;
  LaunchServiceProvider? launchServiceProvider;
  Rocket? rocket;
  Mission? mission;
  Pad? pad;
  List<ArticleInfo>? infoUrls;
  List<VideoInfo>? vidUrls;
  bool? webcastLive;
  String? image;
  dynamic? infographic;
  List<dynamic>? program;
  int? orbitalLaunchAttemptCount;
  int? locationLaunchAttemptCount;
  int? padLaunchAttemptCount;
  int? agencyLaunchAttemptCount;
  int? orbitalLaunchAttemptCountYear;
  int? locationLaunchAttemptCountYear;
  int? padLaunchAttemptCountYear;
  int? agencyLaunchAttemptCountYear;
  List<MissionPatch>? missionPatches;

  Launch(
      {id,
      url,
      slug,
      flightclubUrl,
      rSpacexApiId,
      name,
      status,
      lastUpdated,
      updates,
      net,
      windowEnd,
      windowStart,
      probability,
      holdreason,
      failreason,
      hashtag,
      launchServiceProvider,
      rocket,
      mission,
      pad,
      infoUrls,
      vidUrls,
      webcastLive,
      image,
      infographic,
      program,
      orbitalLaunchAttemptCount,
      locationLaunchAttemptCount,
      padLaunchAttemptCount,
      agencyLaunchAttemptCount,
      orbitalLaunchAttemptCountYear,
      locationLaunchAttemptCountYear,
      padLaunchAttemptCountYear,
      agencyLaunchAttemptCountYear,
      missionPatches});

  Launch.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    url = json["url"];
    slug = json["slug"];
    flightclubUrl = json["flightclub_url"];
    rSpacexApiId = json["r_spacex_api_id"];
    name = json["name"];
    status = json["status"] == null ? null : Status.fromJson(json["status"]);
    lastUpdated = json["last_updated"];
    updates = json["updates"] == null
        ? null
        : (json["updates"] as List).map((e) => Update.fromJson(e)).toList();
    net = json["net"];
    windowEnd = json["window_end"];
    windowStart = json["window_start"];
    probability = json["probability"];
    holdreason = json["holdreason"];
    failreason = json["failreason"];
    hashtag = json["hashtag"];
    launchServiceProvider = json["launch_service_provider"] == null
        ? null
        : LaunchServiceProvider.fromJson(json["launch_service_provider"]);
    rocket = json["rocket"] == null ? null : Rocket.fromJson(json["rocket"]);
    mission =
        json["mission"] == null ? null : Mission.fromJson(json["mission"]);
    pad = json["pad"] == null ? null : Pad.fromJson(json["pad"]);

    infoUrls = json["infoURLs"] == []
        ? null
        : (json["infoURLs"] as List)
            .map((e) => ArticleInfo.fromJson(e))
            .toList();

    vidUrls = json["vidURLs"] == null
        ? null
        : (json["vidURLs"] as List).map((e) => VideoInfo.fromJson(e)).toList();
    webcastLive = json["webcast_live"];
    image = json["image"];
    infographic = json["infographic"];
    program = json["program"] ?? [];
    orbitalLaunchAttemptCount = json["orbital_launch_attempt_count"];
    locationLaunchAttemptCount = json["location_launch_attempt_count"];
    padLaunchAttemptCount = json["pad_launch_attempt_count"];
    agencyLaunchAttemptCount = json["agency_launch_attempt_count"];
    orbitalLaunchAttemptCountYear = json["orbital_launch_attempt_count_year"];
    locationLaunchAttemptCountYear = json["location_launch_attempt_count_year"];
    padLaunchAttemptCountYear = json["pad_launch_attempt_count_year"];
    agencyLaunchAttemptCountYear = json["agency_launch_attempt_count_year"];
    missionPatches = json["mission_patches"] == null
        ? null
        : (json["mission_patches"] as List)
            .map((e) => MissionPatch.fromJson(e))
            .toList();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["id"] = id;
    data["url"] = url;
    data["slug"] = slug;
    data["flightclub_url"] = flightclubUrl;
    data["r_spacex_api_id"] = rSpacexApiId;
    data["name"] = name;
    if (status != null) data["status"] = status?.toJson();
    data["last_updated"] = lastUpdated;
    if (updates != null)
      data["updates"] = updates?.map((e) => e.toJson()).toList();
    data["net"] = net;
    data["window_end"] = windowEnd;
    data["window_start"] = windowStart;
    data["probability"] = probability;
    data["holdreason"] = holdreason;
    data["failreason"] = failreason;
    data["hashtag"] = hashtag;
    if (launchServiceProvider != null)
      data["launch_service_provider"] = launchServiceProvider?.toJson();
    if (rocket != null) data["rocket"] = rocket?.toJson();
    if (mission != null) data["mission"] = mission?.toJson();
    if (pad != null) data["pad"] = pad?.toJson();
    if (infoUrls != null) data["infoURLs"] = infoUrls;
    if (vidUrls != null) data["vidURLs"] = vidUrls;
    data["webcast_live"] = webcastLive;
    data["image"] = image;
    data["infographic"] = infographic;
    if (program != null) data["program"] = program;
    data["orbital_launch_attempt_count"] = orbitalLaunchAttemptCount;
    data["location_launch_attempt_count"] = locationLaunchAttemptCount;
    data["pad_launch_attempt_count"] = padLaunchAttemptCount;
    data["agency_launch_attempt_count"] = agencyLaunchAttemptCount;
    data["orbital_launch_attempt_count_year"] = orbitalLaunchAttemptCountYear;
    data["location_launch_attempt_count_year"] = locationLaunchAttemptCountYear;
    data["pad_launch_attempt_count_year"] = padLaunchAttemptCountYear;
    data["agency_launch_attempt_count_year"] = agencyLaunchAttemptCountYear;
    if (missionPatches != null)
      data["mission_patches"] = missionPatches?.map((e) => e.toJson()).toList();
    return data;
  }
}

class MissionPatch {
  int? id;
  String? name;
  int? priority;
  String? imageUrl;
  Agency? agency;

  MissionPatch({id, name, priority, imageUrl, agency});

  MissionPatch.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    name = json["name"];
    priority = json["priority"];
    imageUrl = json["image_url"];
    agency = json["agency"] == null ? null : Agency.fromJson(json["agency"]);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["id"] = id;
    data["name"] = name;
    data["priority"] = priority;
    data["image_url"] = imageUrl;
    if (agency != null) data["agency"] = agency?.toJson();
    return data;
  }
}

class Agency {
  int? id;
  String? url;
  String? name;
  String? type;

  Agency({id, url, name, type});

  Agency.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    url = json["url"];
    name = json["name"];
    type = json["type"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["id"] = id;
    data["url"] = url;
    data["name"] = name;
    data["type"] = type;
    return data;
  }
}

class Pad {
  int? id;
  String? url;
  int? agencyId;
  String? name;
  dynamic? infoUrl;
  String? wikiUrl;
  String? mapUrl;
  String? latitude;
  String? longitude;
  Location? location;
  String? mapImage;
  int? totalLaunchCount;

  Pad(
      {id,
      url,
      agencyId,
      name,
      infoUrl,
      wikiUrl,
      mapUrl,
      latitude,
      longitude,
      location,
      mapImage,
      totalLaunchCount});

  Pad.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    url = json["url"];
    agencyId = json["agency_id"];
    name = json["name"];
    infoUrl = json["info_url"];
    wikiUrl = json["wiki_url"];
    mapUrl = json["map_url"];
    latitude = json["latitude"];
    longitude = json["longitude"];
    location =
        json["location"] == null ? null : Location.fromJson(json["location"]);
    mapImage = json["map_image"];
    totalLaunchCount = json["total_launch_count"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["id"] = id;
    data["url"] = url;
    data["agency_id"] = agencyId;
    data["name"] = name;
    data["info_url"] = infoUrl;
    data["wiki_url"] = wikiUrl;
    data["map_url"] = mapUrl;
    data["latitude"] = latitude;
    data["longitude"] = longitude;
    if (location != null) data["location"] = location?.toJson();
    data["map_image"] = mapImage;
    data["total_launch_count"] = totalLaunchCount;
    return data;
  }
}

class Location {
  int? id;
  String? url;
  String? name;
  String? countryCode;
  String? mapImage;
  int? totalLaunchCount;
  int? totalLandingCount;

  Location(
      {id,
      url,
      name,
      countryCode,
      mapImage,
      totalLaunchCount,
      totalLandingCount});

  Location.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    url = json["url"];
    name = json["name"];
    countryCode = json["country_code"];
    mapImage = json["map_image"];
    totalLaunchCount = json["total_launch_count"];
    totalLandingCount = json["total_landing_count"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["id"] = id;
    data["url"] = url;
    data["name"] = name;
    data["country_code"] = countryCode;
    data["map_image"] = mapImage;
    data["total_launch_count"] = totalLaunchCount;
    data["total_landing_count"] = totalLandingCount;
    return data;
  }
}

class Mission {
  int? id;
  String? name;
  String? description;
  dynamic? launchDesignator;
  String? type;
  Orbit? orbit;

  Mission({id, name, description, launchDesignator, type, orbit});

  Mission.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    name = json["name"];
    description = json["description"];
    launchDesignator = json["launch_designator"];
    type = json["type"];
    orbit = json["orbit"] == null ? null : Orbit.fromJson(json["orbit"]);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["id"] = id;
    data["name"] = name;
    data["description"] = description;
    data["launch_designator"] = launchDesignator;
    data["type"] = type;
    if (orbit != null) data["orbit"] = orbit?.toJson();
    return data;
  }
}

class Orbit {
  int? id;
  String? name;
  String? abbrev;

  Orbit({id, name, abbrev});

  Orbit.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    name = json["name"];
    abbrev = json["abbrev"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["id"] = id;
    data["name"] = name;
    data["abbrev"] = abbrev;
    return data;
  }
}

class Rocket {
  int? id;
  Configuration? configuration;
  List<dynamic>? launcherStage;
  dynamic? spacecraftStage;

  Rocket({id, configuration, launcherStage, spacecraftStage});

  Rocket.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    configuration = json["configuration"] == null
        ? null
        : Configuration.fromJson(json["configuration"]);
    launcherStage = json["launcher_stage"] ?? [];
    spacecraftStage = json["spacecraft_stage"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["id"] = id;
    if (configuration != null) data["configuration"] = configuration?.toJson();
    if (launcherStage != null) data["launcher_stage"] = launcherStage;
    data["spacecraft_stage"] = spacecraftStage;
    return data;
  }
}

class Configuration {
  int? id;
  String? url;
  String? name;
  String? description;
  String? family;
  String? fullName;
  Manufacturer? manufacturer;
  List<dynamic>? program;
  String? variant;
  String? alias;
  int? minStage;
  int? maxStage;
  double? length;
  double? diameter;
  String? maidenFlight;
  String? launchCost;
  int? launchMass;
  int? leoCapacity;
  dynamic? gtoCapacity;
  int? toThrust;
  dynamic? apogee;
  dynamic? vehicleRange;
  String? imageUrl;
  String? infoUrl;
  String? wikiUrl;
  int? totalLaunchCount;
  int? consecutiveSuccessfulLaunches;
  int? successfulLaunches;
  int? failedLaunches;
  int? pendingLaunches;

  Configuration(
      {id,
      url,
      name,
      description,
      family,
      fullName,
      manufacturer,
      program,
      variant,
      alias,
      minStage,
      maxStage,
      length,
      diameter,
      maidenFlight,
      launchCost,
      launchMass,
      leoCapacity,
      gtoCapacity,
      toThrust,
      apogee,
      vehicleRange,
      imageUrl,
      infoUrl,
      wikiUrl,
      totalLaunchCount,
      consecutiveSuccessfulLaunches,
      successfulLaunches,
      failedLaunches,
      pendingLaunches});

  Configuration.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    url = json["url"];
    name = json["name"];
    description = json["description"];
    family = json["family"];
    fullName = json["full_name"];
    manufacturer = json["manufacturer"] == null
        ? null
        : Manufacturer.fromJson(json["manufacturer"]);
    program = json["program"] ?? [];
    variant = json["variant"];
    alias = json["alias"];
    minStage = json["min_stage"];
    maxStage = json["max_stage"];
    length = json["length"];
    diameter = json["diameter"];
    maidenFlight = json["maiden_flight"];
    launchCost = json["launch_cost"];
    launchMass = json["launch_mass"];
    leoCapacity = json["leo_capacity"];
    gtoCapacity = json["gto_capacity"];
    toThrust = json["to_thrust"];
    apogee = json["apogee"];
    vehicleRange = json["vehicle_range"];
    imageUrl = json["image_url"];
    infoUrl = json["info_url"];
    wikiUrl = json["wiki_url"];
    totalLaunchCount = json["total_launch_count"];
    consecutiveSuccessfulLaunches = json["consecutive_successful_launches"];
    successfulLaunches = json["successful_launches"];
    failedLaunches = json["failed_launches"];
    pendingLaunches = json["pending_launches"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["id"] = id;
    data["url"] = url;
    data["name"] = name;
    data["description"] = description;
    data["family"] = family;
    data["full_name"] = fullName;
    if (manufacturer != null) data["manufacturer"] = manufacturer?.toJson();
    if (program != null) data["program"] = program;
    data["variant"] = variant;
    data["alias"] = alias;
    data["min_stage"] = minStage;
    data["max_stage"] = maxStage;
    data["length"] = length;
    data["diameter"] = diameter;
    data["maiden_flight"] = maidenFlight;
    data["launch_cost"] = launchCost;
    data["launch_mass"] = launchMass;
    data["leo_capacity"] = leoCapacity;
    data["gto_capacity"] = gtoCapacity;
    data["to_thrust"] = toThrust;
    data["apogee"] = apogee;
    data["vehicle_range"] = vehicleRange;
    data["image_url"] = imageUrl;
    data["info_url"] = infoUrl;
    data["wiki_url"] = wikiUrl;
    data["total_launch_count"] = totalLaunchCount;
    data["consecutive_successful_launches"] = consecutiveSuccessfulLaunches;
    data["successful_launches"] = successfulLaunches;
    data["failed_launches"] = failedLaunches;
    data["pending_launches"] = pendingLaunches;
    return data;
  }
}

class Manufacturer {
  int? id;
  String? url;
  String? name;
  bool? featured;
  String? type;
  String? countryCode;
  String? abbrev;
  String? description;
  String? administrator;
  String? foundingYear;
  String? launchers;
  String? spacecraft;
  String? launchLibraryUrl;
  int? totalLaunchCount;
  int? consecutiveSuccessfulLaunches;
  int? successfulLaunches;
  int? failedLaunches;
  int? pendingLaunches;
  int? consecutiveSuccessfulLandings;
  int? successfulLandings;
  int? failedLandings;
  int? attemptedLandings;
  String? infoUrl;
  String? wikiUrl;
  String? logoUrl;
  String? imageUrl;
  String? nationUrl;

  Manufacturer(
      {id,
      url,
      name,
      featured,
      type,
      countryCode,
      abbrev,
      description,
      administrator,
      foundingYear,
      launchers,
      spacecraft,
      launchLibraryUrl,
      totalLaunchCount,
      consecutiveSuccessfulLaunches,
      successfulLaunches,
      failedLaunches,
      pendingLaunches,
      consecutiveSuccessfulLandings,
      successfulLandings,
      failedLandings,
      attemptedLandings,
      infoUrl,
      wikiUrl,
      logoUrl,
      imageUrl,
      nationUrl});

  Manufacturer.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    url = json["url"];
    name = json["name"];
    featured = json["featured"];
    type = json["type"];
    countryCode = json["country_code"];
    abbrev = json["abbrev"];
    description = json["description"];
    administrator = json["administrator"];
    foundingYear = json["founding_year"];
    launchers = json["launchers"];
    spacecraft = json["spacecraft"];
    launchLibraryUrl = json["launch_library_url"];
    totalLaunchCount = json["total_launch_count"];
    consecutiveSuccessfulLaunches = json["consecutive_successful_launches"];
    successfulLaunches = json["successful_launches"];
    failedLaunches = json["failed_launches"];
    pendingLaunches = json["pending_launches"];
    consecutiveSuccessfulLandings = json["consecutive_successful_landings"];
    successfulLandings = json["successful_landings"];
    failedLandings = json["failed_landings"];
    attemptedLandings = json["attempted_landings"];
    infoUrl = json["info_url"];
    wikiUrl = json["wiki_url"];
    logoUrl = json["logo_url"];
    imageUrl = json["image_url"];
    nationUrl = json["nation_url"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["id"] = id;
    data["url"] = url;
    data["name"] = name;
    data["featured"] = featured;
    data["type"] = type;
    data["country_code"] = countryCode;
    data["abbrev"] = abbrev;
    data["description"] = description;
    data["administrator"] = administrator;
    data["founding_year"] = foundingYear;
    data["launchers"] = launchers;
    data["spacecraft"] = spacecraft;
    data["launch_library_url"] = launchLibraryUrl;
    data["total_launch_count"] = totalLaunchCount;
    data["consecutive_successful_launches"] = consecutiveSuccessfulLaunches;
    data["successful_launches"] = successfulLaunches;
    data["failed_launches"] = failedLaunches;
    data["pending_launches"] = pendingLaunches;
    data["consecutive_successful_landings"] = consecutiveSuccessfulLandings;
    data["successful_landings"] = successfulLandings;
    data["failed_landings"] = failedLandings;
    data["attempted_landings"] = attemptedLandings;
    data["info_url"] = infoUrl;
    data["wiki_url"] = wikiUrl;
    data["logo_url"] = logoUrl;
    data["image_url"] = imageUrl;
    data["nation_url"] = nationUrl;
    return data;
  }
}

class LaunchServiceProvider {
  int? id;
  String? url;
  String? name;
  bool? featured;
  String? type;
  String? countryCode;
  String? abbrev;
  String? description;
  String? administrator;
  String? foundingYear;
  String? launchers;
  String? spacecraft;
  String? launchLibraryUrl;
  int? totalLaunchCount;
  int? consecutiveSuccessfulLaunches;
  int? successfulLaunches;
  int? failedLaunches;
  int? pendingLaunches;
  int? consecutiveSuccessfulLandings;
  int? successfulLandings;
  int? failedLandings;
  int? attemptedLandings;
  String? infoUrl;
  String? wikiUrl;
  String? logoUrl;
  String? imageUrl;
  String? nationUrl;

  LaunchServiceProvider(
      {id,
      url,
      name,
      featured,
      type,
      countryCode,
      abbrev,
      description,
      administrator,
      foundingYear,
      launchers,
      spacecraft,
      launchLibraryUrl,
      totalLaunchCount,
      consecutiveSuccessfulLaunches,
      successfulLaunches,
      failedLaunches,
      pendingLaunches,
      consecutiveSuccessfulLandings,
      successfulLandings,
      failedLandings,
      attemptedLandings,
      infoUrl,
      wikiUrl,
      logoUrl,
      imageUrl,
      nationUrl});

  LaunchServiceProvider.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    url = json["url"];
    name = json["name"];
    featured = json["featured"];
    type = json["type"];
    countryCode = json["country_code"];
    abbrev = json["abbrev"];
    description = json["description"];
    administrator = json["administrator"];
    foundingYear = json["founding_year"];
    launchers = json["launchers"];
    spacecraft = json["spacecraft"];
    launchLibraryUrl = json["launch_library_url"];
    totalLaunchCount = json["total_launch_count"];
    consecutiveSuccessfulLaunches = json["consecutive_successful_launches"];
    successfulLaunches = json["successful_launches"];
    failedLaunches = json["failed_launches"];
    pendingLaunches = json["pending_launches"];
    consecutiveSuccessfulLandings = json["consecutive_successful_landings"];
    successfulLandings = json["successful_landings"];
    failedLandings = json["failed_landings"];
    attemptedLandings = json["attempted_landings"];
    infoUrl = json["info_url"];
    wikiUrl = json["wiki_url"];
    logoUrl = json["logo_url"];
    imageUrl = json["image_url"];
    nationUrl = json["nation_url"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["id"] = id;
    data["url"] = url;
    data["name"] = name;
    data["featured"] = featured;
    data["type"] = type;
    data["country_code"] = countryCode;
    data["abbrev"] = abbrev;
    data["description"] = description;
    data["administrator"] = administrator;
    data["founding_year"] = foundingYear;
    data["launchers"] = launchers;
    data["spacecraft"] = spacecraft;
    data["launch_library_url"] = launchLibraryUrl;
    data["total_launch_count"] = totalLaunchCount;
    data["consecutive_successful_launches"] = consecutiveSuccessfulLaunches;
    data["successful_launches"] = successfulLaunches;
    data["failed_launches"] = failedLaunches;
    data["pending_launches"] = pendingLaunches;
    data["consecutive_successful_landings"] = consecutiveSuccessfulLandings;
    data["successful_landings"] = successfulLandings;
    data["failed_landings"] = failedLandings;
    data["attempted_landings"] = attemptedLandings;
    data["info_url"] = infoUrl;
    data["wiki_url"] = wikiUrl;
    data["logo_url"] = logoUrl;
    data["image_url"] = imageUrl;
    data["nation_url"] = nationUrl;
    return data;
  }
}

class Update {
  int? id;
  String? profileImage;
  String? comment;
  String? infoUrl;
  String? createdBy;
  String? createdOn;

  Update({id, profileImage, comment, infoUrl, createdBy, createdOn});

  Update.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    profileImage = json["profile_image"];
    comment = json["comment"];
    infoUrl = json["info_url"];
    createdBy = json["created_by"];
    createdOn = json["created_on"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["id"] = id;
    data["profile_image"] = profileImage;
    data["comment"] = comment;
    data["info_url"] = infoUrl;
    data["created_by"] = createdBy;
    data["created_on"] = createdOn;
    return data;
  }
}

class Status {
  int? id;
  String? name;
  String? abbrev;
  String? description;

  Status({id, name, abbrev, description});

  Status.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    name = json["name"];
    abbrev = json["abbrev"];
    description = json["description"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["id"] = id;
    data["name"] = name;
    data["abbrev"] = abbrev;
    data["description"] = description;
    return data;
  }
}

class VideoInfo {
  int? priority;
  String? title;
  String? description;
  String? featureImage;
  String? url;

  VideoInfo(
      {this.priority,
      this.title,
      this.description,
      this.featureImage,
      this.url});

  VideoInfo.fromJson(Map<String, dynamic> json) {
    priority = json['priority'];
    title = json['title'];
    description = json['description'];
    featureImage = json['feature_image'];
    url = json['url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['priority'] = this.priority;
    data['title'] = this.title;
    data['description'] = this.description;
    data['feature_image'] = this.featureImage;
    data['url'] = this.url;
    return data;
  }
}

class ArticleInfo {
  ArticleInfo({
    required this.priority,
    required this.title,
    required this.description,
    required this.featureImage,
    required this.url,
  });

  final int? priority;
  final String? title;
  final String? description;
  final String? featureImage;
  final String? url;

  factory ArticleInfo.fromJson(Map<String, dynamic> json) {
    return ArticleInfo(
      priority: json["priority"],
      title: json["title"],
      description: json["description"],
      featureImage: json["feature_image"],
      url: json["url"],
    );
  }
}
