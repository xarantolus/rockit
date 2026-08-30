import 'package:flutter/material.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/mixins/date_format.dart';
import 'package:rockit/mixins/time_diff.dart';
import 'package:rockit/widgets/addons/time_refresh.dart';

class LaunchCountDownWidget extends StatefulWidget {
  const LaunchCountDownWidget(this.launch, {super.key});

  final Launch launch;

  @override
  State<LaunchCountDownWidget> createState() => _LaunchCountDownWidgetState();
}

class _LaunchCountDownWidgetState extends State<LaunchCountDownWidget>
    with DateFormatter, TimeDiff {
  /// Seconds only while a clock with seconds on it is on screen. Outside the
  /// countdown this shows a plain date, and redrawing that sixty times a
  /// minute changes nothing.
  late final TimeRefresh _refresh = TimeRefresh(() {
    setState(() {});
    _syncRefresh();
  })..mounted = (() => mounted);

  late DateTime? net;
  late DateTime? windowStart;

  @override
  void initState() {
    super.initState();

    // Parsed at the API boundary now, so these are already DateTimes.
    net = widget.launch.net;
    windowStart = widget.launch.windowStart;

    _syncRefresh();
  }

  /// A clock is only on screen while the countdown is; the rest of the time
  /// this is a date, which changes at midnight and not before.
  void _syncRefresh() {
    final date = net ?? windowStart;
    if (date == null) {
      _refresh.sync(TimeRefreshRate.none);
      return;
    }

    final until = timeDiff(date);
    final showsClock =
        !until.isNegative &&
        (until < const Duration(days: 7) || forceCountdown);

    _refresh.sync(
      showsClock ? TimeRefreshRate.everySecond : TimeRefreshRate.atMidnight,
    );
  }

  bool forceCountdown = false;

  @override
  void dispose() {
    _refresh.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bigTextStyle = TextStyle(fontSize: 30, fontWeight: FontWeight.w800);

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
      final formattedDate = formatDateTimeFriendly(
        context,
        displayedDate.toLocal(),
      );

      textAbove = formattedDate.isFriendly
          ? AppLocalizations.of(context)!.launchWas
          : AppLocalizations.of(context)!.launchWasOn;

      dateText = formattedDate.text;
      if (formattedDate.isFriendly) {
        additionalNote = formatDateTimeLocal(context, displayedDate);
      }
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
          _syncRefresh();
        });
      },
      child: Container(
        // OK, this is really weird:
        // The container only takes the full width when we set a background color
        color: Colors.transparent,
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            if (textAbove.isNotEmpty) Text(textAbove),
            Text(dateText, style: bigTextStyle),
            if (additionalNote.isNotEmpty) Text(additionalNote),
          ],
        ),
      ),
    );
  }
}
