import 'dart:async';

import 'package:rockit/time/precision_time.dart';

/// How often a piece of time-dependent text actually goes out of date.
enum TimeRefreshRate {
  /// Never: there is no date on screen, so nothing rots.
  none,

  /// A clock with seconds on it.
  everySecond,

  /// Everything else. "Today", "Tomorrow", "Yesterday", a weekday, a month —
  /// all of it is phrased relative to the current day and turns over at
  /// midnight, and nothing in between changes what is shown.
  atMidnight,
}

/// Owns the timer a time-dependent widget needs, and no more than that.
///
/// The point is the *rate*. Every widget here used to run a one-second timer
/// whenever it might ever count down, so a launch three days out redrew its
/// date sixty times a minute to render the same string, once per card. The
/// only thing that made it invisible is that it was cheap; it was still every
/// card in a listing, forever.
///
/// Rebuilding is left to the caller: this only decides when.
class TimeRefresh {
  TimeRefresh(this.onDue);

  /// Called when the text is due to be looked at again.
  final void Function() onDue;

  Timer? _timer;
  TimeRefreshRate _rate = TimeRefreshRate.none;

  /// Whether [onDue] should still be reaching a live widget.
  bool Function()? mounted;

  /// Schedules for [rate], leaving an already-correct timer alone.
  void sync(TimeRefreshRate rate) {
    if (rate == _rate && (_timer != null || rate == TimeRefreshRate.none)) {
      return;
    }

    cancel();
    _rate = rate;

    switch (rate) {
      case TimeRefreshRate.everySecond:
        _timer = Timer.periodic(const Duration(seconds: 1), (_) => _fire());

      case TimeRefreshRate.atMidnight:
        // Scheduled exactly rather than polled: a listing holds one of these
        // per card, and waking them all every few minutes to redraw nothing
        // is the very thing this class exists to avoid.
        _timer = Timer(untilNextLocalMidnight(DateTime.now()), _fire);

      case TimeRefreshRate.none:
        break;
    }
  }

  void _fire() {
    if (mounted?.call() == false) {
      cancel();
      return;
    }

    onDue();
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _rate = TimeRefreshRate.none;
  }
}
