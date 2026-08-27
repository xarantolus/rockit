// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'common.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DatePrecision _$DatePrecisionFromJson(Map<String, dynamic> json) =>
    DatePrecision(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      abbrev: json['abbrev'] as String?,
      description: json['description'] as String?,
    );

ImageLicense _$ImageLicenseFromJson(Map<String, dynamic> json) =>
    ImageLicense(name: json['name'] as String?, link: json['link'] as String?);

ApiImage _$ApiImageFromJson(Map<String, dynamic> json) => ApiImage(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  imageUrl: json['image_url'] as String?,
  thumbnailUrl: json['thumbnail_url'] as String?,
  credit: json['credit'] as String?,
  license: json['license'] == null
      ? null
      : ImageLicense.fromJson(json['license'] as Map<String, dynamic>),
);

Agency _$AgencyFromJson(Map<String, dynamic> json) => Agency(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  abbrev: json['abbrev'] as String?,
  type: namedFromJson(json['type']),
  description: json['description'] as String?,
  infoUrl: json['info_url'] as String?,
  wikiUrl: json['wiki_url'] as String?,
  logo: ApiImage.fromJsonOrUrl(json['logo']),
  image: ApiImage.fromJsonOrUrl(json['image']),
);

Orbit _$OrbitFromJson(Map<String, dynamic> json) => Orbit(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  abbrev: json['abbrev'] as String?,
);

MissionPatch _$MissionPatchFromJson(Map<String, dynamic> json) => MissionPatch(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  image: ApiImage.fromJsonOrUrl(json['image']),
  priority: (json['priority'] as num?)?.toInt(),
);

Update _$UpdateFromJson(Map<String, dynamic> json) => Update(
  id: (json['id'] as num?)?.toInt(),
  comment: json['comment'] as String?,
  infoUrl: json['info_url'] as String?,
  createdBy: json['created_by'] as String?,
  createdOn: json['created_on'] == null
      ? null
      : DateTime.parse(json['created_on'] as String),
  profileImage: json['profile_image'] as String?,
);

ContentUrl _$ContentUrlFromJson(Map<String, dynamic> json) => ContentUrl(
  title: json['title'] as String?,
  description: json['description'] as String?,
  url: json['url'] as String?,
  source: json['source'] as String?,
  publisher: json['publisher'] as String?,
  featureImage: json['feature_image'] as String?,
  live: json['live'] as bool?,
  startTime: json['start_time'] == null
      ? null
      : DateTime.parse(json['start_time'] as String),
  endTime: json['end_time'] == null
      ? null
      : DateTime.parse(json['end_time'] as String),
);

Program _$ProgramFromJson(Map<String, dynamic> json) => Program(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  description: json['description'] as String?,
  image: ApiImage.fromJsonOrUrl(json['image']),
  infoUrl: json['info_url'] as String?,
  wikiUrl: json['wiki_url'] as String?,
  type: namedFromJson(json['type']),
  agencies:
      (json['agencies'] as List<dynamic>?)
          ?.map((e) => Agency.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);
