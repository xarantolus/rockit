/// How long ago something happened, in the coarsest unit that still reads
/// naturally.
library;

enum RelativeUnit {
  /// Less than a minute old.
  justNow,
  minutes,
  hours,
  days,

  /// Older than a week — show the actual date instead, because "23 days ago"
  /// is harder to place than "4 Aug".
  absolute,
}

class RelativeTime {
  const RelativeTime(this.unit, [this.value = 0]);

  final RelativeUnit unit;
  final int value;

  @override
  bool operator ==(Object other) =>
      other is RelativeTime && other.unit == unit && other.value == value;

  @override
  int get hashCode => Object.hash(unit, value);

  @override
  String toString() => 'RelativeTime($unit, $value)';
}

/// Buckets the gap between [when] and [now].
///
/// A future timestamp reads as [RelativeUnit.justNow] rather than a negative
/// age: news sites do occasionally publish with a clock a little ahead, and
/// "in -3 minutes" is worse than "just now".
RelativeTime relativeTime(DateTime when, DateTime now) {
  final age = now.difference(when);

  if (age.inMinutes < 1) {
    return const RelativeTime(RelativeUnit.justNow);
  }
  if (age.inMinutes < 60) {
    return RelativeTime(RelativeUnit.minutes, age.inMinutes);
  }
  if (age.inHours < 24) {
    return RelativeTime(RelativeUnit.hours, age.inHours);
  }
  if (age.inDays < 7) {
    return RelativeTime(RelativeUnit.days, age.inDays);
  }

  return const RelativeTime(RelativeUnit.absolute);
}
