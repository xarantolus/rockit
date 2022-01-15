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

  String formatDateTime(BuildContext context, DateTime d) {
    final localization = AppLocalizations.of(context)!;

    final use24h = MediaQuery.of(context).alwaysUse24HourFormat;

    final DateFormat formatter = DateFormat(
      use24h ? localization.dateTimeFormat24h : localization.dateTimeFormat,
      localization.localeName,
    );

    return formatter.format(d);
  }

  String formatDate(BuildContext context, DateTime d) {
    final localization = AppLocalizations.of(context)!;

    final DateFormat formatter = DateFormat(
      d.year == DateTime.now().year ? localization.currentYearDateFormat : localization.dateFormat,
      localization.localeName,
    );

    return formatter.format(d);
  }

  String formatTime(BuildContext context, DateTime d) {
    final localization = AppLocalizations.of(context)!;

    final use24h = MediaQuery.of(context).alwaysUse24HourFormat;

    final DateFormat formatter = DateFormat(
      use24h ? localization.timeFormat24h : localization.timeFormat,
      localization.localeName,
    );

    return formatter.format(d);
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

    return FriendlyDateResult.no(f(context, d));
  }
}
