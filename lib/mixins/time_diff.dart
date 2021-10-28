import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

mixin TimeDiff {
  Duration timeDiff(DateTime date) {
    final now = DateTime.now().toUtc();

    return date.toUtc().difference(now);
  }

  String formatTimeDiff(BuildContext context, Duration d) {
    if (d.isNegative) {
      return AppLocalizations.of(context)!.inThePast;
    }

    var prefix = "";

    if (d.inDays == 1) {
      prefix = AppLocalizations.of(context)!.oneDay + ", ";
    } else if (d.inDays > 1) {
      prefix = "${d.inDays} ${AppLocalizations.of(context)!.days}, ";
    }

    String twoDigits(int d) {
      if (d < 10) {
        return "0$d";
      }
      return "$d";
    }

    return "$prefix${d.inHours % 24}:${twoDigits(d.inMinutes % 60)}:${twoDigits(d.inSeconds % 60)}";
  }
}
