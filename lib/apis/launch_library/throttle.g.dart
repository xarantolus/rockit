// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'throttle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiThrottle _$ApiThrottleFromJson(Map<String, dynamic> json) => ApiThrottle(
  yourRequestLimit: (json['your_request_limit'] as num?)?.toInt(),
  limitFrequencySecs: (json['limit_frequency_secs'] as num?)?.toInt(),
  currentUse: (json['current_use'] as num?)?.toInt(),
  nextUseSecs: (json['next_use_secs'] as num?)?.toInt(),
  ident: json['ident'] as String?,
);
