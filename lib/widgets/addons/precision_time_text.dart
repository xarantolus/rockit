import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rockit/apis/launch_library/common.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/mixins/date_format.dart';
import 'package:rockit/time/precision_time.dart';

/// Shows a launch or event time honouring how precisely the API knows it.
///
/// Only ticks when there is something real to tick towards. That is not just
/// honesty — most launches are month- or quarter-precision, so this also stops
/// the app running a one-second timer per visible card for dates that will not
/// change all year.
class PrecisionTimeText extends StatefulWidget {
  const PrecisionTimeText({
    required this.date,
    required this.precision,
    this.style,
    this.countdownStyle,
    super.key,
  });

  final DateTime? date;
  final DatePrecision? precision;

  /// Used for the non-ticking forms (a day, a month, a quarter).
  final TextStyle? style;

  /// Used for the ticking countdown, which usually wants to be bigger and
  /// tabular so the digits do not jitter.
  final TextStyle? countdownStyle;

  @override
  State<PrecisionTimeText> createState() => _PrecisionTimeTextState();
}

class _PrecisionTimeTextState extends State<PrecisionTimeText>
    with DateFormatter {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(PrecisionTimeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Starts a one-second timer only for a real countdown, and stops it again if
  /// the launch slips to a vaguer date.
  void _syncTicker() {
    final needsTicker =
        timeDisplayFor(widget.date, widget.precision) == TimeDisplay.countdown;

    if (needsTicker && _ticker == null) {
      _ticker = Timer.periodic(
        const Duration(seconds: 1),
        (_) => setState(() {}),
      );
    } else if (!needsTicker) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  String _monthYear(BuildContext context, DateTime date) {
    final localizations = AppLocalizations.of(context)!;

    return DateFormat(
      localizations.monthYearFormat,
      localizations.localeName,
    ).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final date = widget.date;
    final display = timeDisplayFor(date, widget.precision);

    if (date == null || display == TimeDisplay.unknown) {
      return Text(localizations.launchTimeUnknown, style: widget.style);
    }

    final local = date.toLocal();

    switch (display) {
      case TimeDisplay.countdown:
        return Text(
          Countdown.between(local, DateTime.now()).clock,
          style: (widget.countdownStyle ?? widget.style)?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );

      case TimeDisplay.day:
        return Text(formatDate(context, local), style: widget.style);

      case TimeDisplay.pastDateTime:
        return Text(formatDateTime(context, local), style: widget.style);

      case TimeDisplay.month:
        return Text(
          "${localizations.netPrefix} ${_monthYear(context, local)}",
          style: widget.style,
        );

      case TimeDisplay.quarter:
        return Text(
          "${localizations.netPrefix} "
          "${localizations.quarterWindow(quarterOf(local), '${local.year}')}",
          style: widget.style,
        );

      case TimeDisplay.year:
        return Text(
          "${localizations.netPrefix} ${local.year}",
          style: widget.style,
        );

      case TimeDisplay.unknown:
        return Text(localizations.launchTimeUnknown, style: widget.style);
    }
  }
}
