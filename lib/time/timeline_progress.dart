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

/// Whether a ticking clock is worth running for this timeline.
///
/// Only true between the first and last milestone. A launch days away, or one
/// long finished, does not need a timer per second.
bool timelineIsRunning({
  required List<Duration> offsets,
  required Duration elapsed,
}) {
  if (offsets.isEmpty) {
    return false;
  }

  return elapsed >= offsets.first && elapsed <= offsets.last;
}
