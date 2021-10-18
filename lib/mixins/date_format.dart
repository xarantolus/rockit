import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

mixin DateFormatter {
  String formatDateTimeLocal(BuildContext context, DateTime d) {
    return formatDateTime(context, d.toLocal());
  }

  String formatDateTime(BuildContext context, DateTime d) {
    final localization = AppLocalizations.of(context)!;

    final DateFormat formatter =
        DateFormat(localization.dateTimeFormat, localization.localeName);

    return formatter.format(d);
  }

  String formatDate(BuildContext context, DateTime d) {
    final localization = AppLocalizations.of(context)!;

    final DateFormat formatter =
        DateFormat(localization.dateFormat, localization.localeName);

    return formatter.format(d);
  }
}
