import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rockit/launch_library/json_convert.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CountDownWidget extends StatefulWidget {
  const CountDownWidget(this.launch, {Key? key}) : super(key: key);

  final Launch launch;

  @override
  _CountDownWidgetState createState() => _CountDownWidgetState();
}

class _CountDownWidgetState extends State<CountDownWidget> {
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

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Duration timeDiff(DateTime date) {
    final now = DateTime.now().toUtc();

    return date.toUtc().difference(now);
  }

  String displayTimeDiff(Duration d) {
    var prefix = "";

    if (d.inDays == 1) {
      prefix = AppLocalizations.of(context)!.oneDay + ", ";
    } else if (d.inDays > 1) {
      prefix = "${d.inDays} ${AppLocalizations.of(context)!.days}, ";
    }

    return "$prefix${d.inHours % 24}:${d.inMinutes % 60}:${d.inSeconds % 60}";
  }

  String formatDate(DateTime d) {
    final localization = AppLocalizations.of(context)!;

    final DateFormat formatter =
        DateFormat(localization.dateTimeFormat, localization.localeName);

    return formatter.format(d.toLocal());
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

    if (timeUntil < const Duration(days: 7)) {
      textAbove = net != null
          ? AppLocalizations.of(context)!.launchIsIn
          : windowStart != null
              ? AppLocalizations.of(context)!.windowIsIn
              : "";

      dateText = displayTimeDiff(timeUntil);
      additionalNote = formatDate(displayedDate);
    } else {
      textAbove = net != null
          ? AppLocalizations.of(context)!.launchIsOn
          : windowStart != null
              ? AppLocalizations.of(context)!.windowIsOn
              : "";

      dateText = formatDate(displayedDate);
      additionalNote = AppLocalizations.of(context)!.inYourLocalTime;
    }

    return Column(
      children: [
        Text(textAbove),
        Text(
          dateText,
          style: bigTextStyle,
        ),
        Text(additionalNote),
      ],
    );
  }
}
