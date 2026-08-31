import 'package:intl/intl.dart';
import 'package:rockit/apis/launch_library/common.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/time/precision_time.dart';

/// Every way the app writes a date, given only the strings and the clock
/// preference.
///
/// Deliberately no `BuildContext`: the home-screen widget's text is written by
/// the background isolate, which has no element tree to look one up in, and a
/// second implementation of "Today, 12:05" would be a second set of rules to
/// keep in step. The [DateFormatter] mixin is a thin wrapper that reads both
/// values off a context.
class FriendlyDates {
  const FriendlyDates(this.l10n, {required this.use24h});

  final AppLocalizations l10n;
  final bool use24h;

  String _format(DateTime d, String layout) =>
      DateFormat(layout, l10n.localeName).format(d);

  String dateTime(DateTime d) =>
      _format(d, use24h ? l10n.dateTimeFormat24h : l10n.dateTimeFormat);

  String date(DateTime d) => _format(
    d,
    d.year == DateTime.now().year
        ? l10n.currentYearDateFormat
        : l10n.dateFormat,
  );

  String time(DateTime d) =>
      _format(d, use24h ? l10n.timeFormat24h : l10n.timeFormat);

  static bool _sameDay(DateTime a, DateTime b) =>
      a.day == b.day && a.month == b.month && a.year == b.year;

  /// "Today, 12:05" and the like, falling back to [full] when the date is far
  /// enough out that naming the day says more than the weekday would.
  String friendly(DateTime at, String Function(DateTime) full) {
    final d = at.toLocal();
    final now = DateTime.now().toLocal();

    if (_sameDay(d, now)) {
      return "${l10n.today}, ${time(d)}";
    }

    if (_sameDay(d, now.subtract(const Duration(days: 1)))) {
      return "${l10n.yesterday}, ${time(d)}";
    }

    if (_sameDay(d, now.add(const Duration(days: 1)))) {
      return "${l10n.tomorrow}, ${time(d)}";
    }

    // Inside the next week the weekday alone locates it.
    final days = _daysBetween(now, d);
    if (days > 0 && days < 7) {
      return _format(
        d,
        use24h ? l10n.currentWeekDateFormat24h : l10n.currentWeekDateFormat,
      );
    }

    return full(d);
  }

  String friendlyDateTimeText(DateTime d) => friendly(d, dateTime);
}

// https://stackoverflow.com/a/67679455
int _daysBetween(DateTime from, DateTime to) {
  from = DateTime(from.year, from.month, from.day);
  to = DateTime(to.year, to.month, to.day);

  return (to.difference(from).inHours / 24).round();
}

/// The text under a launch or event: a friendly time when the API knows one, a
/// "NET October 2026" when it only knows the month.
///
/// Shared by [PrecisionTimeText] and the home-screen widget so the two cannot
/// disagree — the widget's text is written by the background isolate, which has
/// no context to build a widget in.
String precisionTimeText(
  FriendlyDates dates,
  DateTime? date,
  DatePrecision? precision, {
  DateTime? now,
}) {
  final l10n = dates.l10n;
  final display = timeDisplayFor(date, precision, now: now);

  if (date == null || display == TimeDisplay.unknown) {
    return l10n.launchTimeUnknown;
  }

  final local = date.toLocal();

  switch (display) {
    // A countdown is a live thing; anywhere that cannot tick shows the time it
    // is counting to instead.
    case TimeDisplay.countdown:
      return dates.friendlyDateTimeText(local);

    case TimeDisplay.day:
      return dates.date(local);

    case TimeDisplay.pastDateTime:
      return dates.dateTime(local);

    case TimeDisplay.month:
      return "${l10n.netPrefix} "
          "${DateFormat(l10n.monthYearFormat, l10n.localeName).format(local)}";

    case TimeDisplay.quarter:
      return "${l10n.netPrefix} "
          "${l10n.quarterWindow(quarterOf(local), '${local.year}')}";

    case TimeDisplay.year:
      return "${l10n.netPrefix} ${local.year}";

    // Floored, so a date in 2031 known only to the decade reads "2030s".
    case TimeDisplay.decade:
      return "${l10n.netPrefix} ${local.year ~/ 10 * 10}s";

    case TimeDisplay.unknown:
      return l10n.launchTimeUnknown;
  }
}
