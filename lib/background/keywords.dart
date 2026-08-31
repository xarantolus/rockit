/// Matching launches against the keywords a user wants subscribing to
/// automatically.
///
/// Pure: no storage, no notifications, no widgets, so the rules that decide
/// whether someone gets subscribed to something can be tested directly.
library;

import 'dart:convert';

import 'package:rockit/apis/launch_library/launch_response.dart';

/// A word to watch for, and how far ahead to watch.
class LaunchKeyword {
  const LaunchKeyword({required this.text, this.days = defaultDays});

  /// Half a year: enough to catch the next few launches of a programme,
  /// without reaching launches whose date is still a guess.
  static const defaultDays = 180;

  final String text;
  final int days;

  Duration get window => Duration(days: days);

  /// Matching is case-insensitive, so this is what the comparison uses.
  String get needle => text.trim().toLowerCase();

  bool get isUsable => needle.isNotEmpty && days > 0;

  LaunchKeyword copyWith({String? text, int? days}) =>
      LaunchKeyword(text: text ?? this.text, days: days ?? this.days);

  Map<String, Object?> toJson() => {'text': text, 'days': days};

  static LaunchKeyword? fromJson(Object? json) {
    if (json is! Map) {
      return null;
    }

    final text = json['text'];
    if (text is! String || text.trim().isEmpty) {
      return null;
    }

    final days = json['days'];

    return LaunchKeyword(
      text: text,
      days: days is int && days > 0 ? days : defaultDays,
    );
  }

  static String encode(List<LaunchKeyword> keywords) =>
      jsonEncode(keywords.map((k) => k.toJson()).toList());

  /// Anything unreadable is dropped rather than throwing: a keyword list that
  /// cannot be parsed must not stop the app subscribing to anything.
  static List<LaunchKeyword> decode(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final parsed = jsonDecode(raw);
      if (parsed is! List) {
        return const [];
      }

      return parsed
          .map(LaunchKeyword.fromJson)
          .whereType<LaunchKeyword>()
          .where((k) => k.isUsable)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  bool operator ==(Object other) =>
      other is LaunchKeyword && other.text == text && other.days == days;

  @override
  int get hashCode => Object.hash(text, days);
}

/// Whether [launch] is one [keyword] is asking about.
///
/// Name and rocket, never the provider: "spacex" would otherwise mean the
/// whole listing rather than a watchlist.
bool keywordMatches(LaunchKeyword keyword, Launch launch) {
  final needle = keyword.needle;
  if (needle.isEmpty) {
    return false;
  }

  for (final field in [launch.name, launch.rocketName]) {
    if ((field ?? "").toLowerCase().contains(needle)) {
      return true;
    }
  }

  return false;
}

/// Whether the API knows when this launch is, well enough to act on it: a
/// month or a quarter means reminders for a date nobody has set yet.
bool _dateIsFirmEnough(DatePrecision? precision) {
  switch (precision?.kind) {
    case DatePrecisionKind.second:
    case DatePrecisionKind.minute:
    case DatePrecisionKind.hour:
    case DatePrecisionKind.day:
      return true;
    default:
      return false;
  }
}

/// The launches out of [launches] that should be subscribed to now.
///
/// **[declined] is final**: every unsubscribe writes into it, so a launch taken
/// off the list is never put back whatever the keywords say. That is the
/// invariant the feature rests on. Already-subscribed is skipped, which also
/// stops a second notification about the same launch.
List<Launch> launchesToAutoSubscribe({
  required Iterable<Launch> launches,
  required Iterable<LaunchKeyword> keywords,
  required Set<String> subscribed,
  required Set<String> declined,
  required DateTime now,
}) {
  final usable = keywords.where((k) => k.isUsable).toList();
  if (usable.isEmpty) {
    return const [];
  }

  final picked = <Launch>[];
  final seen = <String>{};

  for (final launch in launches) {
    final id = launch.id;
    final net = launch.net;

    if (id == null ||
        net == null ||
        subscribed.contains(id) ||
        declined.contains(id) ||
        seen.contains(id) ||
        !_dateIsFirmEnough(launch.netPrecision) ||
        !net.isAfter(now)) {
      continue;
    }

    for (final keyword in usable) {
      if (net.isAfter(now.add(keyword.window)) ||
          !keywordMatches(keyword, launch)) {
        continue;
      }

      picked.add(launch);
      seen.add(id);
      break;
    }
  }

  return picked;
}
