import 'package:json_annotation/json_annotation.dart';

part 'common.g.dart';

/// Shared Launch Library 2.3.0 value types.
///
/// Only what the app renders is modelled — the API also returns social media
/// links, celestial bodies, launcher families and payload operators, which
/// would be thousands of lines nobody reads.
///
/// Every field is nullable on purpose. Keys genuinely come and go: they differ
/// between the `list` / `normal` / `detailed` response modes, and between API
/// versions. A nullable field with a missing key decodes to null; a
/// non-nullable one would throw and take the whole listing down with it.

/// Reads a value the API has changed the type of, or that arrives as a string
/// in cached 2.2.0 responses.
double? doubleFromJson(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? intFromJson(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// `type` is a bare string in 2.2.0 and an object with a `name` in 2.3.0.
String? namedFromJson(Object? value) {
  if (value is String) return value;
  if (value is Map) return value['name'] as String?;
  return null;
}

/// How precisely the API actually knows a date.
///
/// This is the most important field the app was ignoring. In a sample of 30
/// upcoming launches only 7 were known to the minute, while 9 were accurate
/// merely to a *quarter*; events are never known to a time at all. Rendering a
/// ticking countdown for those claims a precision the data does not have.
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class DatePrecision {
  const DatePrecision({this.id, this.name, this.abbrev, this.description});

  final int? id;
  final String? name;
  final String? abbrev;
  final String? description;

  factory DatePrecision.fromJson(Map<String, dynamic> json) =>
      _$DatePrecisionFromJson(json);

  /// Maps the API vocabulary onto something we can switch on.
  ///
  /// Matching is on `abbrev` because the ids are sparse (0, 1, 5, 7, 10, 14…)
  /// and new ones appear. Quarters arrive as `Q1`–`Q4` and half-years as
  /// `H1`/`H2`; both mean "some months this year", so they collapse together.
  /// The abbreviations come from `/2.3.0/config/net_precisions/`, which
  /// enumerates all seventeen. The longer spellings are kept as a fallback in
  /// case the vocabulary ever changes under us.
  DatePrecisionKind get kind {
    switch (abbrev?.toUpperCase()) {
      case 'SEC':
        return DatePrecisionKind.second;
      case 'MIN':
        return DatePrecisionKind.minute;
      case 'HR':
      case 'HOUR':
        return DatePrecisionKind.hour;
      // Morning and Afternoon pin the day but not the clock, so they are a
      // day as far as anything we render is concerned.
      case 'AM':
      case 'PM':
      case 'DAY':
        return DatePrecisionKind.day;
      case 'WK':
      case 'WEEK':
        return DatePrecisionKind.week;
      case 'M':
      case 'MONTH':
        return DatePrecisionKind.month;
      case 'Q1':
      case 'Q2':
      case 'Q3':
      case 'Q4':
      case 'H1':
      case 'H2':
        return DatePrecisionKind.quarter;
      case 'Y':
      case 'FY':
      case 'YEAR':
        return DatePrecisionKind.year;
      case 'DEC':
        return DatePrecisionKind.decade;
    }
    return DatePrecisionKind.unknown;
  }
}

enum DatePrecisionKind {
  second,
  minute,
  hour,
  day,
  week,
  month,
  quarter,
  year,
  decade,

  /// Something the API added that we do not know yet. Treated as imprecise,
  /// which is the safe direction to be wrong in.
  unknown;

  /// True only when the API claims the clock time itself is meaningful.
  /// Anything coarser must never be shown as a live countdown.
  bool get hasUsableTime => this == second || this == minute || this == hour;
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class ImageLicense {
  const ImageLicense({this.name, this.link});

  final String? name;
  final String? link;

  factory ImageLicense.fromJson(Map<String, dynamic> json) =>
      _$ImageLicenseFromJson(json);
}

/// An image as 2.3.0 returns it — an object, where 2.2.0 sent a bare URL.
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class ApiImage {
  const ApiImage({
    this.id,
    this.name,
    this.imageUrl,
    this.thumbnailUrl,
    this.credit,
    this.license,
  });

  final int? id;
  final String? name;
  final String? imageUrl;
  final String? thumbnailUrl;
  final String? credit;
  final ImageLicense? license;

  /// Measured against the live API: thumbnails are 256x256 square crops of a
  /// 1920x1280 original (~11 KB against ~180 KB).
  static const thumbnailPixels = 256;

  factory ApiImage.fromJson(Map<String, dynamic> json) =>
      _$ApiImageFromJson(json);

  /// Tolerates the bare URL string 2.2.0 used, so a cached response written by
  /// an older build still decodes.
  static ApiImage? fromJsonOrUrl(Object? value) {
    if (value is Map<String, dynamic>) return ApiImage.fromJson(value);
    if (value is String && value.isNotEmpty) return ApiImage(imageUrl: value);
    return null;
  }

  /// The cheapest URL that still has enough pixels for the box it goes in.
  ///
  /// [displayPixels] is the largest edge of that box in *physical* pixels
  /// (logical size x devicePixelRatio). The thumbnail is only used when it is
  /// genuinely big enough; above 256px it would upscale into mush, and its
  /// square crop is the wrong aspect ratio for a wide card anyway.
  String? urlFor(double displayPixels) {
    if (displayPixels <= thumbnailPixels && thumbnailUrl != null) {
      return thumbnailUrl;
    }
    return imageUrl ?? thumbnailUrl;
  }
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class Agency {
  const Agency({
    this.id,
    this.name,
    this.abbrev,
    this.type,
    this.description,
    this.infoUrl,
    this.wikiUrl,
    this.logo,
    this.image,
  });

  final int? id;
  final String? name;
  final String? abbrev;

  @JsonKey(fromJson: namedFromJson)
  final String? type;

  final String? description;
  final String? infoUrl;
  final String? wikiUrl;

  @JsonKey(fromJson: ApiImage.fromJsonOrUrl)
  final ApiImage? logo;

  @JsonKey(fromJson: ApiImage.fromJsonOrUrl)
  final ApiImage? image;

  factory Agency.fromJson(Map<String, dynamic> json) => _$AgencyFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class Orbit {
  const Orbit({this.id, this.name, this.abbrev});

  final int? id;
  final String? name;
  final String? abbrev;

  /// The API says an unknown orbit with values rather than by leaving the
  /// object out: `{"abbrev": "N/A", "name": "Unknown"}`. Printing that back at
  /// the user is worse than saying nothing, so callers get null instead.
  static const _placeholders = {"n/a", "unknown", "tbd", ""};

  String? get label {
    for (final value in [abbrev, name]) {
      final text = value?.trim();
      if (text != null && !_placeholders.contains(text.toLowerCase())) {
        return text;
      }
    }

    return null;
  }

  factory Orbit.fromJson(Map<String, dynamic> json) => _$OrbitFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class MissionPatch {
  const MissionPatch({this.id, this.name, this.image, this.priority});

  final int? id;
  final String? name;

  @JsonKey(fromJson: ApiImage.fromJsonOrUrl)
  final ApiImage? image;

  final int? priority;

  factory MissionPatch.fromJson(Map<String, dynamic> json) =>
      _$MissionPatchFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class Update {
  const Update({
    this.id,
    this.comment,
    this.infoUrl,
    this.createdBy,
    this.createdOn,
    this.profileImage,
  });

  final int? id;
  final String? comment;
  final String? infoUrl;
  final String? createdBy;
  final DateTime? createdOn;
  final String? profileImage;

  factory Update.fromJson(Map<String, dynamic> json) => _$UpdateFromJson(json);
}

/// An article, stream or other link. Covers both `info_urls` and `vid_urls`;
/// the video-only fields are simply null for info links.
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class ContentUrl {
  const ContentUrl({
    this.title,
    this.description,
    this.url,
    this.source,
    this.publisher,
    this.featureImage,
    this.live,
    this.startTime,
    this.endTime,
  });

  final String? title;
  final String? description;
  final String? url;
  final String? source;
  final String? publisher;
  final String? featureImage;

  /// 2.3.0 marks streams that are live right now.
  final bool? live;
  final DateTime? startTime;
  final DateTime? endTime;

  factory ContentUrl.fromJson(Map<String, dynamic> json) =>
      _$ContentUrlFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class Program {
  const Program({
    this.id,
    this.name,
    this.description,
    this.image,
    this.infoUrl,
    this.wikiUrl,
    this.type,
    this.agencies = const [],
  });

  final int? id;
  final String? name;
  final String? description;

  @JsonKey(fromJson: ApiImage.fromJsonOrUrl)
  final ApiImage? image;

  final String? infoUrl;
  final String? wikiUrl;

  @JsonKey(fromJson: namedFromJson)
  final String? type;

  /// The constructor default covers a missing or null key.
  final List<Agency> agencies;

  factory Program.fromJson(Map<String, dynamic> json) =>
      _$ProgramFromJson(json);
}
