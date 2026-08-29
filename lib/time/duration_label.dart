/// The parts of a duration worth showing, coarsest first.
///
/// Event durations from the API are hours and minutes — a static fire window is
/// `PT3H32M12S`, a press conference `PT1H2M35S` — so rendering them in whole
/// days turned every one of them into "0 days". Seconds are dropped: nothing
/// showing a duration here is precise enough for them to mean anything.
///
/// Returns an empty list for anything under a minute, which is the caller's cue
/// to show nothing at all rather than "0 minutes".
List<DurationPart> durationParts(Duration duration) {
  if (duration.inMinutes < 1) {
    return const [];
  }

  final days = duration.inDays;
  final hours = duration.inHours.remainder(24);
  final minutes = duration.inMinutes.remainder(60);

  return [
    if (days > 0) DurationPart(DurationUnit.days, days),
    if (hours > 0) DurationPart(DurationUnit.hours, hours),
    // Minutes alongside days would be false precision on something that long.
    if (minutes > 0 && days == 0) DurationPart(DurationUnit.minutes, minutes),
  ];
}

enum DurationUnit { days, hours, minutes }

class DurationPart {
  const DurationPart(this.unit, this.value);

  final DurationUnit unit;
  final int value;

  @override
  bool operator ==(Object other) =>
      other is DurationPart && other.unit == unit && other.value == value;

  @override
  int get hashCode => Object.hash(unit, value);

  @override
  String toString() => "$value ${unit.name}";
}
