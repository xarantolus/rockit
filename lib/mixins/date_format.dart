import 'package:flutter/widgets.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/time/friendly_dates.dart';

export 'package:rockit/time/friendly_dates.dart' show FriendlyDateResult;

/// The date formatting a widget needs, read off its context.
///
/// The rules themselves live in [FriendlyDates], which takes no context, so the
/// background isolate can write the same strings for the home-screen widget.
mixin DateFormatter {
  FriendlyDates _dates(BuildContext context) => FriendlyDates(
    AppLocalizations.of(context)!,
    use24h: MediaQuery.of(context).alwaysUse24HourFormat,
  );

  String formatDateTimeLocal(BuildContext context, DateTime d) =>
      _dates(context).dateTimeLocal(d);

  String formatDateTime(BuildContext context, DateTime d) =>
      _dates(context).dateTime(d);

  String formatDate(BuildContext context, DateTime d) =>
      _dates(context).date(d);

  String formatTime(BuildContext context, DateTime d) =>
      _dates(context).time(d);

  String formatDateTimeFriendlyText(BuildContext context, DateTime d) =>
      _dates(context).friendlyDateTimeText(d);

  FriendlyDateResult formatDateTimeFriendly(BuildContext context, DateTime d) =>
      _dates(context).friendlyDateTime(d);

  String formatDateFriendly(BuildContext context, DateTime d) =>
      _dates(context).friendlyDateText(d);
}
