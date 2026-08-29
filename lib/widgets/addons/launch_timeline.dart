import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/time/precision_time.dart';
import 'package:rockit/time/timeline_progress.dart';

/// The countdown milestones, with whichever one is happening right now lit up.
///
/// The highlight only appears when the API actually knows the launch time to
/// the minute — for a month-precision launch "what is happening now" is not a
/// meaningful question.
class LaunchTimeline extends StatefulWidget {
  const LaunchTimeline({
    required this.events,
    required this.net,
    required this.precision,
    super.key,
  });

  final List<TimelineEvent> events;
  final DateTime? net;
  final DatePrecision? precision;

  @override
  State<LaunchTimeline> createState() => _LaunchTimelineState();
}

class _LaunchTimelineState extends State<LaunchTimeline> {
  Timer? _ticker;

  /// Entries that carry an offset, in order. The API usually sends them sorted
  /// but nothing promises it, and the active-entry rule depends on the order.
  late List<TimelineEvent> _ordered = _order(widget.events);

  static List<TimelineEvent> _order(List<TimelineEvent> events) {
    final withOffset = events.where((e) => e.relativeTime != null).toList()
      ..sort((a, b) => a.relativeTime!.compareTo(b.relativeTime!));

    return withOffset;
  }

  List<Duration> get _offsets =>
      _ordered.map((e) => e.relativeTime!).toList(growable: false);

  /// How far we are from T-0 right now; negative before liftoff.
  Duration? get _elapsed {
    final net = widget.net;
    if (net == null || !hasUsableTime(widget.precision)) {
      return null;
    }
    return DateTime.now().difference(net);
  }

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(LaunchTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ordered = _order(widget.events);
    _syncTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Runs a clock only while the timeline is actually in progress. A launch
  /// three days out does not need a timer per second.
  void _syncTicker() {
    final elapsed = _elapsed;
    final wanted =
        elapsed != null &&
        timelineIsRunning(offsets: _offsets, elapsed: elapsed);

    if (wanted && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {});
        // Stop as soon as the last milestone passes.
        _syncTicker();
      });
    } else if (!wanted) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  static String _offsetLabel(Duration d) {
    final abs = d.abs();
    final sign = d.isNegative ? "T-" : "T+";

    if (abs.inHours > 0) {
      return "$sign${abs.inHours}h ${abs.inMinutes.remainder(60)}m";
    }
    if (abs.inMinutes > 0) {
      return "$sign${abs.inMinutes}m ${abs.inSeconds.remainder(60)}s";
    }
    return "$sign${abs.inSeconds}s";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final elapsed = _elapsed;
    final active = elapsed == null
        ? null
        : activeTimelineIndex(offsets: _offsets, elapsed: elapsed);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _ordered.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(vertical: 1),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: i == active
                    ? theme.colorScheme.primary.withValues(alpha: 0.16)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 84,
                    child: Text(
                      _offsetLabel(_ordered[i].relativeTime!),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: i == active ? theme.colorScheme.primary : null,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _ordered[i].type ?? _ordered[i].description ?? "",
                      style: TextStyle(
                        fontWeight: i == active
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
