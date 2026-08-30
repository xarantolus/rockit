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
  Timer? _timer;

  /// Longest nap while the timeline is still ahead.
  ///
  /// The wait is capped rather than scheduled for the exact moment because a
  /// timer does not run while the app is in the background: an exact one for a
  /// launch hours out would fire however late the phone had been asleep.
  /// Waking periodically re-reads the clock instead.
  static const _maxWait = Duration(minutes: 5);

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
    _syncTimer();
  }

  @override
  void didUpdateWidget(LaunchTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ordered = _order(widget.events);

    // A refresh can move `net` or the milestones, so any pending wait is for
    // the wrong moment. _syncTimer replaces it.
    _syncTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Wakes only when the highlight actually moves.
  ///
  /// The rows are fixed offsets, so between milestones there is nothing to
  /// redraw — a timer per second spent the whole countdown rebuilding the list
  /// to show the same thing. And "not running yet" is not "nothing will
  /// happen": with nothing scheduled at all, a page opened an hour early never
  /// lit up, however long it was left open.
  void _syncTimer() {
    _timer?.cancel();
    _timer = null;

    final elapsed = _elapsed;
    if (elapsed == null) {
      return;
    }

    final until = untilNextTimelineChange(offsets: _offsets, elapsed: elapsed);
    if (until == null) {
      return;
    }

    _timer = Timer(until < _maxWait ? until : _maxWait, () {
      if (!mounted) return;
      setState(() {});
      _syncTimer();
    });
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
                      timelineOffsetLabel(_ordered[i].relativeTime!),
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
