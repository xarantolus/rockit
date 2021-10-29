import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rockit/apis/launch_library/upcoming_response.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rockit/mixins/date_format.dart';
import 'package:rockit/mixins/time_diff.dart';

class LaunchCountDownWidget extends StatefulWidget {
  const LaunchCountDownWidget(this.launch, {Key? key}) : super(key: key);

  final Launch launch;

  @override
  _LaunchCountDownWidgetState createState() => _LaunchCountDownWidgetState();
}

class _LaunchCountDownWidgetState extends State<LaunchCountDownWidget>
    with DateFormatter, TimeDiff {
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

    // If there's no official Go for launch time, it's speculation
    final timeIsSpeculation = (widget.launch.status?.abbrev != "Go");

    if (timeUntil.isNegative) {
      textAbove = AppLocalizations.of(context)!.launchWasOn;
      dateText = formatDateTimeLocal(context, displayedDate);
    } else if (timeUntil < const Duration(days: 7) || forceCountdown) {
      if (net != null) {
        textAbove = timeIsSpeculation
            ? AppLocalizations.of(context)!.launchMightBeIn
            : AppLocalizations.of(context)!.launchIsIn;
      } else if (windowStart != null) {
        textAbove = AppLocalizations.of(context)!.windowIsIn;
      }

      dateText = formatTimeDiff(context, timeUntil);
      additionalNote = formatDateTimeLocal(context, displayedDate);
    } else {
      if (net != null) {
        textAbove = timeIsSpeculation
            ? AppLocalizations.of(context)!.launchMightBeOn
            : AppLocalizations.of(context)!.launchIsOn;
      } else if (windowStart != null) {
        textAbove = AppLocalizations.of(context)!.windowIsOn;
      }

      dateText = formatDateTimeLocal(context, displayedDate);
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
          if (textAbove.isNotEmpty) Text(textAbove),
          Text(
            dateText,
            style: bigTextStyle,
          ),
          if (additionalNote.isNotEmpty) Text(additionalNote),
        ],
      ),
    );
  }
}
