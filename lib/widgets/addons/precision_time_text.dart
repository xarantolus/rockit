import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rockit/apis/launch_library/common.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/mixins/date_format.dart';
import 'package:rockit/time/precision_time.dart';
import 'package:rockit/widgets/addons/time_refresh.dart';

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
    this.showCountdown = true,
    super.key,
  });

  final DateTime? date;
  final DatePrecision? precision;

  /// Used for the non-ticking forms (a day, a month, a quarter).
  final TextStyle? style;

  /// Used for the ticking countdown, which usually wants to be bigger and
  /// tabular so the digits do not jitter.
  final TextStyle? countdownStyle;

  /// False renders a friendly local time — "Tomorrow, 11:26 AM" — where a
  /// countdown would otherwise tick.
  ///
  /// The listings use this. A wall of clocks counting down is harder to read
  /// than a set of times, and it also means the app is not running a
  /// per-second timer for every card on screen. The countdown belongs on the
  /// page you opened deliberately.
  final bool showCountdown;

  @override
  State<PrecisionTimeText> createState() => _PrecisionTimeTextState();
}

class _PrecisionTimeTextState extends State<PrecisionTimeText>
    with DateFormatter {
  late final TimeRefresh _refresh = TimeRefresh(() {
    setState(() {});
    // The rate can change under us: a countdown reaching its stale age stops
    // being a countdown, and a midnight wake needs the next one booking.
    _syncTicker();
  })..mounted = (() => mounted);

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
    _refresh.cancel();
    super.dispose();
  }

  /// A second-by-second clock only for a real countdown; otherwise the text is
  /// a date phrased relative to today, so it goes stale at midnight and not
  /// before. Without the latter a card saying "Tomorrow, 11:26" still says it
  /// after midnight, when it means today.
  void _syncTicker() {
    final display = timeDisplayFor(widget.date, widget.precision);

    _refresh.sync(
      display == TimeDisplay.unknown
          ? TimeRefreshRate.none
          : widget.showCountdown && display == TimeDisplay.countdown
          ? TimeRefreshRate.everySecond
          : TimeRefreshRate.atMidnight,
    );
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
        if (!widget.showCountdown) {
          return Text(
            formatDateTimeFriendlyText(context, local),
            style: widget.style,
          );
        }

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

      case TimeDisplay.decade:
        // Floored, so a date in 2031 known only to the decade reads "2030s".
        return Text(
          "${localizations.netPrefix} ${local.year ~/ 10 * 10}s",
          style: widget.style,
        );

      case TimeDisplay.unknown:
        return Text(localizations.launchTimeUnknown, style: widget.style);
    }
  }
}
