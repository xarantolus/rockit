/// Deciding *how* to show a launch or event time, given how precisely the API
/// claims to know it.
///
/// The app used to render a ticking second-by-second countdown for everything.
/// That is wrong for most of the schedule: in a 30-launch sample only 7 launches
/// were known to the minute, 14 only to the month and 9 only to a *quarter*,
/// and events are never known to a time at all. A clock counting down to a date
/// that is really "sometime in Q3" is not a small inaccuracy, it is a claim the
/// data does not support.
///
/// This file is deliberately pure — no widgets, no localisation — so the rules
/// can be tested directly.
library;

import 'package:rockit/apis/launch_library/common.dart';

/// How a given time should be presented.
enum TimeDisplay {
  /// A live countdown, ticking. Only for times the API knows to the
  /// minute or better.
  countdown,

  /// A specific calendar day, with no clock time.
  day,

  /// A named month, e.g. "NET September 2026".
  month,

  /// A quarter or half-year, e.g. "NET Q3 2026".
  quarter,

  /// A bare year.
  year,

  /// No usable date at all.
  unknown,
}

/// Picks the presentation for [date] at [precision].
///
/// An unknown precision degrades to [TimeDisplay.day] rather than a countdown:
/// if the API adds a vocabulary entry we do not recognise, showing a date
/// without a clock is the safe way to be wrong.
TimeDisplay timeDisplayFor(DateTime? date, DatePrecision? precision) {
  if (date == null) {
    return TimeDisplay.unknown;
  }

  switch (precision?.kind) {
    case DatePrecisionKind.second:
    case DatePrecisionKind.minute:
    case DatePrecisionKind.hour:
      return TimeDisplay.countdown;

    case DatePrecisionKind.day:
    case DatePrecisionKind.week:
      return TimeDisplay.day;

    case DatePrecisionKind.month:
      return TimeDisplay.month;

    case DatePrecisionKind.quarter:
      return TimeDisplay.quarter;

    case DatePrecisionKind.year:
      return TimeDisplay.year;

    case DatePrecisionKind.unknown:
      return TimeDisplay.day;

    // Older cached responses have no precision field at all. They predate the
    // 2.3.0 migration, so assume the old behaviour of a usable time.
    case null:
      return TimeDisplay.countdown;
  }
}

/// True when the time component is meaningful and may be shown to the user.
bool hasUsableTime(DatePrecision? precision) =>
    timeDisplayFor(DateTime.now(), precision) == TimeDisplay.countdown;

/// The calendar quarter (1-4) that [date] falls in.
int quarterOf(DateTime date) => ((date.month - 1) ~/ 3) + 1;

/// A countdown broken into the parts a UI wants to show.
///
/// [isPast] rather than a negative [duration] because "T+" and "T-" are
/// rendered differently, and callers should not have to remember to take an
/// absolute value.
class Countdown {
  const Countdown({
    required this.days,
    required this.hours,
    required this.minutes,
    required this.seconds,
    required this.isPast,
  });

  final int days;
  final int hours;
  final int minutes;
  final int seconds;

  /// True once the target time has passed.
  final bool isPast;

  /// Splits the gap between [target] and [now].
  factory Countdown.between(DateTime target, DateTime now) {
    final difference = target.difference(now);
    final absolute = difference.abs();

    return Countdown(
      days: absolute.inDays,
      hours: absolute.inHours.remainder(24),
      minutes: absolute.inMinutes.remainder(60),
      seconds: absolute.inSeconds.remainder(60),
      isPast: difference.isNegative,
    );
  }

  /// `T-03:12:45`, or `T-2d 03:12:45` once it is more than a day out.
  ///
  /// Days are shown separately rather than rolled into hours because a
  /// three-digit hour count is unreadable.
  String get clock {
    String two(int value) => value.toString().padLeft(2, '0');

    final time = "${two(hours)}:${two(minutes)}:${two(seconds)}";
    final sign = isPast ? "T+" : "T-";

    return days > 0 ? "$sign${days}d $time" : "$sign$time";
  }
}
