import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/mixins/date_format.dart';
import 'package:rockit/mixins/time_diff.dart';

class EventCountDownWidget extends StatefulWidget {
  const EventCountDownWidget(this.event, {Key? key}) : super(key: key);

  final Event event;

  @override
  _EventCountDownWidgetState createState() => _EventCountDownWidgetState();
}

class _EventCountDownWidgetState extends State<EventCountDownWidget>
    with DateFormatter, TimeDiff {
  late Timer _timer;

  @override
  void initState() {
    super.initState();

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

    var textAbove = "", dateText = "", additionalNote = "";

    final date = widget.event.date!;

    var timeUntil = timeDiff(date);
    if (timeUntil.isNegative) {
      final formattedDate = formatDateTimeFriendly(
        context,
        date.toLocal(),
      );

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
            Text(
              dateText,
              style: bigTextStyle,
            ),
            if (additionalNote.isNotEmpty) Text(additionalNote),
          ],
        ),
      ),
    );
  }
}
