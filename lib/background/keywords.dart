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

  /// How far ahead to look by default.
  ///
  /// Half a year: far enough that a keyword set today catches the next few
  /// launches of a programme, near enough that it does not subscribe to
  /// something two years out whose date is still a guess.
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
/// Deliberately the launch name and the rocket, and *not* the provider: a
/// keyword is meant to follow a programme or a vehicle. Matching the provider
/// would make "spacex" mean every SpaceX launch there is, which is not a
/// watchlist, it is the whole listing.
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

/// Whether the API knows when this launch is well enough to act on it.
///
/// A month or a quarter is a guess, and subscribing to a guess means reminders
/// for a date nobody has set yet.
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
/// The rules, in the order they matter:
///
/// - **[declined] is final.** Every unsubscribe writes into it, so a launch the
///   user has taken off the list is never put back, whatever the keywords say.
///   This is the invariant the whole feature rests on.
/// - Already subscribed, so nothing to do — which is also what stops a second
///   notification about the same launch.
/// - The date has to be real ([_dateIsFirmEnough]) and still ahead.
/// - It has to fall inside the window of the keyword that matched, and each
///   keyword carries its own.
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
