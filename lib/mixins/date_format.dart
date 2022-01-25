import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class FriendlyDateResult {
  String text;
  bool isFriendly;

  FriendlyDateResult(this.text, {this.isFriendly = false});

  factory FriendlyDateResult.no(String t) {
    return FriendlyDateResult(t);
  }

  factory FriendlyDateResult.yes(String t) {
    return FriendlyDateResult(t, isFriendly: true);
  }
}

mixin DateFormatter {
  String formatDateTimeLocal(BuildContext context, DateTime d) {
    return formatDateTime(context, d.toLocal());
  }

  String _formatDate(BuildContext context, DateTime d, String layout) {
    final DateFormat formatter = DateFormat(
      layout,
      AppLocalizations.of(context)!.localeName,
    );

    return formatter.format(d);
  }

  String formatDateTime(BuildContext context, DateTime d) {
    final localization = AppLocalizations.of(context)!;
    final use24h = MediaQuery.of(context).alwaysUse24HourFormat;

    return _formatDate(
      context,
      d,
      use24h ? localization.dateTimeFormat24h : localization.dateTimeFormat,
    );
  }

  String formatDate(BuildContext context, DateTime d) {
    final localization = AppLocalizations.of(context)!;

    return _formatDate(
      context,
      d,
      d.year == DateTime.now().year ? localization.currentYearDateFormat : localization.dateFormat,
    );
  }

  String formatTime(BuildContext context, DateTime d) {
    final localization = AppLocalizations.of(context)!;

    final use24h = MediaQuery.of(context).alwaysUse24HourFormat;

    return _formatDate(
      context,
      d,
      use24h ? localization.timeFormat24h : localization.timeFormat,
    );
  }

  bool _equalDay(DateTime d1, DateTime d2) {
    return d1.day == d2.day && d1.month == d2.month && d1.year == d2.year;
  }

  String formatDateTimeFriendlyText(BuildContext context, DateTime d) {
    return formatFriendly(context, d, formatDateTime).text;
  }

  FriendlyDateResult formatDateTimeFriendly(BuildContext context, DateTime d) {
    return formatFriendly(context, d, formatDateTime);
  }

  String formatDateFriendly(BuildContext context, DateTime d) {
    return formatFriendly(context, d, formatDate).text;
  }

  FriendlyDateResult formatFriendly(BuildContext context, DateTime d, String Function(BuildContext, DateTime) f) {
    d = d.toLocal();
    var now = DateTime.now().toLocal();

    if (_equalDay(d, now)) {
      return FriendlyDateResult.yes(
        "${AppLocalizations.of(context)!.today}, ${formatTime(context, d)}",
      );
    }

    if (_equalDay(d, now.subtract(const Duration(days: 1)))) {
      return FriendlyDateResult.yes(
        "${AppLocalizations.of(context)!.yesterday}, ${formatTime(context, d)}",
      );
    }

    if (_equalDay(d, now.add(const Duration(days: 1)))) {
      return FriendlyDateResult.yes(
        "${AppLocalizations.of(context)!.tomorrow}, ${formatTime(context, d)}",
      );
    }

    // If something is within the next week, we only display the day name and time
    var diff = d.difference(now);
    if (!diff.isNegative && diff.inDays < 7) {
      final format24h = MediaQuery.of(context).alwaysUse24HourFormat;

      return FriendlyDateResult.yes(
        _formatDate(
          context,
          d,
          format24h
              ? AppLocalizations.of(context)!.currentWeekDateFormat24h
              : AppLocalizations.of(context)!.currentWeekDateFormat,
        ),
      );
    }

    return FriendlyDateResult.no(f(context, d));
  }
}
