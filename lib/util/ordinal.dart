/// English ordinals, for lines like "223rd launch from this pad".
///
/// The API gives these counts on every launch, and a bare number ("223 launch
/// from this pad") reads badly. The 11-13 exception is the whole reason this is
/// a function with tests rather than a switch on the last digit.
String englishOrdinal(int value) {
  final n = value.abs();

  // 11th, 12th, 13th — and 111th, 212th, 1013th — all take "th" despite
  // ending in 1, 2 and 3.
  final lastTwo = n % 100;
  if (lastTwo >= 11 && lastTwo <= 13) {
    return "${value}th";
  }

  switch (n % 10) {
    case 1:
      return "${value}st";
    case 2:
      return "${value}nd";
    case 3:
      return "${value}rd";
    default:
      return "${value}th";
  }
}
