import 'package:flutter/material.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/mixins/date_format.dart';
import 'package:rockit/mixins/time_diff.dart';
import 'package:rockit/widgets/addons/time_refresh.dart';

class EventCountDownWidget extends StatefulWidget {
  const EventCountDownWidget(this.event, {super.key});

  final Event event;

  @override
  State<EventCountDownWidget> createState() => _EventCountDownWidgetState();
}

class _EventCountDownWidgetState extends State<EventCountDownWidget>
    with DateFormatter, TimeDiff {
  /// Seconds only while a clock with seconds on it is on screen. Outside the
  /// countdown this shows a plain date, and redrawing that sixty times a
  /// minute changes nothing.
  late final TimeRefresh _refresh = TimeRefresh(() {
    setState(() {});
    _syncRefresh();
  })..mounted = (() => mounted);

  @override
  void initState() {
    super.initState();

    _syncRefresh();
  }

  /// A clock is only on screen while the countdown is; the rest of the time
  /// this is a date, which changes at midnight and not before.
  void _syncRefresh() {
    final date = widget.event.date;
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

    var textAbove = "", dateText = "", additionalNote = "";

    final date = widget.event.date!;

    var timeUntil = timeDiff(date);
    if (timeUntil.isNegative) {
      final formattedDate = formatDateTimeFriendly(context, date.toLocal());

      textAbove = formattedDate.isFriendly
          ? AppLocalizations.of(context)!.eventWas
          : AppLocalizations.of(context)!.eventWasOn;

      dateText = formattedDate.text;

      if (formattedDate.isFriendly) {
        additionalNote = formatDateTimeLocal(context, date);
      }
    } else if (timeUntil < const Duration(days: 7) || forceCountdown) {
      textAbove = AppLocalizations.of(context)!.eventIsIn;

      dateText = formatTimeDiff(context, timeUntil);
      additionalNote = formatDateTimeLocal(context, date);
    } else {
      textAbove = AppLocalizations.of(context)!.eventIsOn;

      dateText = formatDateTimeLocal(context, date);
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
