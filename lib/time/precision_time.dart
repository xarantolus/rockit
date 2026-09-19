/// Deciding *how* to show a launch or event time, given how precisely the API
/// claims to know it. Most of the schedule is known only to a month or a
/// quarter, and a ticking clock down to one of those claims what the data does
/// not say.
///
/// Pure — no widgets, no localisation — so the rules can be tested directly.
library;

import 'package:rockit/apis/launch_library/common.dart';

/// How a given time should be presented.
enum TimeDisplay {
  /// A live countdown, ticking. Only for times the API knows to the
  /// minute or better.
  countdown,

  /// A specific calendar day, with no clock time.
  day,

  /// A past launch's exact date and time. Once something is well behind us,
  /// "T+41d 07:12:03" is a number nobody wants; the date it happened is.
  pastDateTime,

  /// A named month, e.g. "NET September 2026".
  month,

  /// A quarter or half-year, e.g. "NET Q3 2026".
  quarter,

  /// A bare year.
  year,

  /// A whole decade, e.g. "NET 2030s". Rare, but the API has a precision for
  /// it, and without this it fell through to a precise calendar day.
  decade,

  /// No usable date at all.
  unknown,
}

/// How long a launch keeps counting up before it is simply history.
///
/// A day or two of "T+" is useful — it is how you tell a launch happened this
/// morning. Six weeks of it is not.
const staleAfterLaunch = Duration(days: 7);

/// Picks the presentation for [date] at [precision].
///
/// An unrecognised precision degrades to [TimeDisplay.day]: showing a date
/// without a clock is the safe way to be wrong. [now] is a parameter so the
/// rules can be tested without waiting.
TimeDisplay timeDisplayFor(
  DateTime? date,
  DatePrecision? precision, {
  DateTime? now,
}) {
  if (date == null) {
    return TimeDisplay.unknown;
  }

  bool isStale() => (now ?? DateTime.now()).difference(date) > staleAfterLaunch;

  switch (precision?.kind) {
    case DatePrecisionKind.second:
    case DatePrecisionKind.minute:
    case DatePrecisionKind.hour:
      return isStale() ? TimeDisplay.pastDateTime : TimeDisplay.countdown;

    case DatePrecisionKind.day:
    case DatePrecisionKind.week:
      return TimeDisplay.day;

    case DatePrecisionKind.month:
      return TimeDisplay.month;

    case DatePrecisionKind.quarter:
      return TimeDisplay.quarter;

    case DatePrecisionKind.year:
      return TimeDisplay.year;

    case DatePrecisionKind.decade:
      return TimeDisplay.decade;

    case DatePrecisionKind.unknown:
      return TimeDisplay.day;

    // Older cached responses have no precision field at all. They predate the
    // 2.3.0 migration, so assume the old behaviour of a usable time.
    case null:
      return isStale() ? TimeDisplay.pastDateTime : TimeDisplay.countdown;
  }
}

/// True when the time component is meaningful and may be shown to the user.
///
/// Asks about *now* deliberately: this is about whether the API knows a clock
/// time at all, not about whether the launch has already happened.
bool hasUsableTime(DatePrecision? precision) {
  final now = DateTime.now();

  return timeDisplayFor(now, precision, now: now) == TimeDisplay.countdown;
}

/// How long until the next local midnight, which is when every friendly label
/// — "Today", "Tomorrow", a weekday, a month — needs looking at again.
///
/// A screen left open across midnight otherwise keeps saying "Tomorrow" about
/// a launch happening today.
Duration untilNextLocalMidnight(DateTime now) {
  final local = now.toLocal();
  final midnight = DateTime(local.year, local.month, local.day + 1);

  return midnight.difference(local);
}

/// The precision to reason with when the API states none.
///
/// A missing precision *renders* as a clock time (see the `null` case in
/// [displayedTimeKey]), so for deciding whether the shown time changed it
/// behaves like minute precision. This is deliberately not the same question
/// as `_dateIsFirmEnough` in the keyword rules, which treats a missing
/// precision as not knowing — there the risk is scheduling reminders against
/// a guess, here it is only what the card says.
DatePrecisionKind effectivePrecision(DatePrecision? precision) =>
    precision?.kind ?? DatePrecisionKind.minute;

/// Whether [a] states a time more precisely than [b].
///
/// [DatePrecisionKind] is declared finest-first, so a lower index is finer.
/// `unknown` sits last, which is the safe direction: something the API has
/// added and we cannot interpret counts as the vaguest thing there is.
bool isFinerThan(DatePrecisionKind a, DatePrecisionKind b) => a.index < b.index;

/// Whichever of [a] and [b] states a time less precisely.
///
/// Comparing two times has to happen at the coarser of the two, or the
/// comparison invents a difference: a launch the API has only dated to a
/// month roams within that month constantly, so checking it against a
/// minute-precise predecessor would report a change every single time.
DatePrecisionKind coarserOf(DatePrecisionKind a, DatePrecisionKind b) =>
    a.index >= b.index ? a : b;

/// A stable identity for the time a user actually sees, so a change in this is
/// exactly a change on screen.
///
/// Not the rendered string, which is relative to *now*: "Tomorrow, 11:26"
/// becomes "Today, 11:26" overnight with nothing having moved.
///
/// **UTC, not local.** The card is rendered in the viewer's timezone, but the
/// *key* must not be, or the viewer's own clock becomes an input: changing
/// timezone re-keyed every subscription and announced a time change for a
/// launch nobody had moved. The trade is that a launch nudged across local —
/// but not UTC — midnight changes the day on the card without notifying,
/// which is the better way round to be wrong.
String? displayedTimeKey(DateTime? date, DatePrecision? precision) =>
    displayedTimeKeyFor(date, effectivePrecision(precision));

/// [displayedTimeKey] against a precision that has already been resolved, so
/// two times can be compared at a granularity neither of them states.
String? displayedTimeKeyFor(DateTime? date, DatePrecisionKind kind) {
  if (date == null) {
    return null;
  }

  final at = date.toUtc();
  String pad(int value, [int width = 2]) =>
      value.toString().padLeft(width, '0');

  final day = "${pad(at.year, 4)}-${pad(at.month)}-${pad(at.day)}";

  switch (kind) {
    // A countdown ticks, so anything down to the minute is on screen.
    case DatePrecisionKind.second:
    case DatePrecisionKind.minute:
    case DatePrecisionKind.hour:
      return "$day ${pad(at.hour)}:${pad(at.minute)}";

    case DatePrecisionKind.day:
    case DatePrecisionKind.week:
    // An unrecognised precision renders as a plain day; see timeDisplayFor.
    case DatePrecisionKind.unknown:
      return day;

    case DatePrecisionKind.month:
      return "${pad(at.year, 4)}-${pad(at.month)}";

    case DatePrecisionKind.quarter:
      return "${pad(at.year, 4)}-Q${quarterOf(at)}";

    case DatePrecisionKind.year:
      return pad(at.year, 4);

    case DatePrecisionKind.decade:
      return "${pad(at.year - at.year % 10, 4)}s";
  }
}

/// Whether [display] names an actual calendar day, rather than a window.
bool showsExactDay(TimeDisplay display) => switch (display) {
  TimeDisplay.countdown || TimeDisplay.pastDateTime || TimeDisplay.day => true,
  _ => false,
};

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
