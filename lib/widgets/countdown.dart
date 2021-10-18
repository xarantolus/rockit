import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rockit/launch_library/json_convert.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rockit/mixins/date_format.dart';

class CountDownWidget extends StatefulWidget {
  const CountDownWidget(this.launch, {Key? key}) : super(key: key);

  final Launch launch;

  @override
  _CountDownWidgetState createState() => _CountDownWidgetState();
}

class _CountDownWidgetState extends State<CountDownWidget> with DateFormatter {
  late Timer _timer;

  late DateTime? net;
  late DateTime? windowStart;

  @override
  void initState() {
    super.initState();

    try {
      net = DateTime.parse(widget.launch.net ?? "");
    } catch (_) {}

    try {
      windowStart = DateTime.parse(widget.launch.windowStart ?? "");
    } catch (_) {}

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  bool forceCountdown = false;

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Duration timeDiff(DateTime date) {
    final now = DateTime.now().toUtc();

    return date.toUtc().difference(now);
  }

  String formatTimeDiff(Duration d) {
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

  @override
  Widget build(BuildContext context) {
    const bigTextStyle = TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w800,
    );

    var displayedDate = net ?? windowStart;

    if (displayedDate == null) {
      return Text(
        AppLocalizations.of(context)!.unknownLaunchTime,
        style: bigTextStyle,
      );
    }

    var textAbove = "", dateText = "", additionalNote = "";

    var timeUntil = timeDiff(displayedDate);

    if (timeUntil < const Duration(days: 7) || forceCountdown) {
      textAbove = net != null
          ? AppLocalizations.of(context)!.launchIsIn
          : windowStart != null
              ? AppLocalizations.of(context)!.windowIsIn
              : "";

      dateText = formatTimeDiff(timeUntil);
      additionalNote = formatDate(context, displayedDate);
    } else {
      textAbove = net != null
          ? AppLocalizations.of(context)!.launchIsOn
          : windowStart != null
              ? AppLocalizations.of(context)!.windowIsOn
              : "";

      dateText = formatDate(context, displayedDate);
      additionalNote = AppLocalizations.of(context)!.inYourLocalTime;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          forceCountdown = !forceCountdown;
        });
      },
      child: Column(
        children: [
          if (!timeUntil.isNegative) Text(textAbove),
          Text(
            dateText,
            style: bigTextStyle,
          ),
          if (!timeUntil.isNegative) Text(additionalNote),
        ],
      ),
    );
  }
}
