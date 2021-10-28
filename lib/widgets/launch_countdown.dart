import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rockit/apis/launch_library/upcoming_response.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rockit/mixins/date_format.dart';

class LaunchCountDownWidget extends StatefulWidget {
  const LaunchCountDownWidget(this.launch, {Key? key}) : super(key: key);

  final Launch launch;

  @override
  _LaunchCountDownWidgetState createState() => _LaunchCountDownWidgetState();
}

class _LaunchCountDownWidgetState extends State<LaunchCountDownWidget> with DateFormatter {
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

    // If there's no official Go for launch time, it's speculation
    final timeIsSpeculation = (widget.launch.status?.abbrev != "Go");

    if (timeUntil < const Duration(days: 7) || forceCountdown) {
      if (net != null) {
        textAbove = timeIsSpeculation
            ? AppLocalizations.of(context)!.launchMightBeIn
            : AppLocalizations.of(context)!.launchIsIn;
      } else if (windowStart != null) {
        textAbove = AppLocalizations.of(context)!.windowIsIn;
      }

      dateText = formatTimeDiff(timeUntil);
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
