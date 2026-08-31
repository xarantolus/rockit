import 'package:flutter/widgets.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/time/friendly_dates.dart';

/// The date formatting a widget needs, read off its context.
///
/// The rules themselves live in [FriendlyDates], which takes no context, so the
/// background isolate can write the same strings for the home-screen widget.
mixin DateFormatter {
  /// The rules, bound to this context's locale and clock setting.
  ///
  /// Public because the precision renderer needs the whole object to hand to
  /// [precisionTimeText], rather than one formatted string.
  FriendlyDates datesOf(BuildContext context) => FriendlyDates(
    AppLocalizations.of(context)!,
    use24h: MediaQuery.alwaysUse24HourFormatOf(context),
  );

  String formatDateTime(BuildContext context, DateTime d) =>
      datesOf(context).dateTime(d);

  String formatDate(BuildContext context, DateTime d) =>
      datesOf(context).date(d);

  String formatTime(BuildContext context, DateTime d) =>
      datesOf(context).time(d);

  String formatDateTimeFriendlyText(BuildContext context, DateTime d) =>
      datesOf(context).friendlyDateTimeText(d);
}
