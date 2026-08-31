/// Working out which countdown milestone is happening right now.
library;

/// Index of the timeline entry currently in progress, or null when none is.
///
/// The API gives each milestone a start offset from T-0 and nothing else —
/// there is no duration and no end time — so an entry is treated as running
/// until the next one begins.
///
/// That has a consequence worth being explicit about: the **last entry is never
/// highlighted**, because nothing says when it finishes. Highlighting it would
/// mean inventing an end, and it would then stay lit forever.
///
/// [offsets] are the entries' offsets from T-0, negative before liftoff.
/// [elapsed] is how far the launch is from T-0 right now, so negative while it
/// is still counting down.
int? activeTimelineIndex({
  required List<Duration> offsets,
  required Duration elapsed,
}) {
  // With fewer than two entries there is never a bounded window.
  if (offsets.length < 2) {
    return null;
  }

  int? active;
  for (var i = 0; i < offsets.length; i++) {
    if (offsets[i] <= elapsed) {
      active = i;
    } else {
      break;
    }
  }

  // Nothing has started yet, or we are past the final milestone and no longer
  // know what is going on.
  if (active == null || active == offsets.length - 1) {
    return null;
  }

  return active;
}

/// How long until the highlight moves, or null when it never will again.
///
/// The rows are fixed offsets and only the highlight changes, so there is
/// nothing to redraw between milestones. Returns a wait even before the
/// timeline starts: with nothing scheduled, a page opened early never lights
/// up at all.
Duration? untilNextTimelineChange({
  required List<Duration> offsets,
  required Duration elapsed,
}) {
  for (final offset in offsets) {
    if (offset > elapsed) {
      return offset - elapsed;
    }
  }

  return null;
}

/// The offset a row is labelled with, e.g. `T-1h 30m` or `T+5m`. Trailing
/// zeroes are dropped, so five minutes past liftoff is not `T+5m 0s`.
String timelineOffsetLabel(Duration offset) {
  if (offset == Duration.zero) {
    return "T-0";
  }

  final abs = offset.abs();
  final sign = offset.isNegative ? "T-" : "T+";

  String pair(int major, String majorUnit, int minor, String minorUnit) =>
      minor == 0
      ? "$sign$major$majorUnit"
      : "$sign$major$majorUnit $minor$minorUnit";

  if (abs.inHours > 0) {
    return pair(abs.inHours, "h", abs.inMinutes.remainder(60), "m");
  }

  if (abs.inMinutes > 0) {
    return pair(abs.inMinutes, "m", abs.inSeconds.remainder(60), "s");
  }

  return "$sign${abs.inSeconds}s";
}
