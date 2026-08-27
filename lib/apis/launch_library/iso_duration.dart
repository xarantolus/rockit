/// ISO-8601 duration parsing for the Launch Library.
///
/// The API sends durations as strings — `P71DT7H48M8S` for a pad turnaround,
/// `-PT18M30S` for a countdown milestone. Parsing them at the API boundary
/// means the rest of the app sees a real [Duration] and can do arithmetic and
/// formatting on it, instead of passing a string around and re-parsing it at
/// every use site.
library;

/// Matches `[-]P[nY][nM][nW][nD][T[nH][nM][nS]]`.
///
/// The `M` before `T` is months and the one after is minutes, which is why the
/// two halves are matched separately rather than with one repeated group.
final _iso8601Duration = RegExp(
  r'^(-)?P'
  r'(?:(\d+)Y)?'
  r'(?:(\d+)M)?'
  r'(?:(\d+)W)?'
  r'(?:(\d+)D)?'
  r'(?:T'
  r'(?:(\d+)H)?'
  r'(?:(\d+)M)?'
  r'(?:(\d+(?:\.\d+)?)S)?'
  r')?$',
);

/// Parses an ISO-8601 duration, returning null for anything unparseable.
///
/// Years and months are rejected rather than approximated: their length depends
/// on the calendar, and a [Duration] cannot express that. The API only ever
/// sends days, hours, minutes and seconds here — across every duration field in
/// a 40-launch sample, the only units used were D, H, M and S — so rejecting
/// the ambiguous ones costs nothing and avoids inventing a wrong number.
Duration? parseIso8601Duration(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  final match = _iso8601Duration.firstMatch(value);
  if (match == null) {
    return null;
  }

  // Years or months present: not representable, so refuse rather than guess.
  if (match.group(2) != null || match.group(3) != null) {
    return null;
  }

  // Every component is optional in the grammar, so "P", "-P" and "PT" all
  // match while carrying no information. Require at least one.
  final hasComponent = [4, 5, 6, 7, 8].any((g) => match.group(g) != null);
  if (!hasComponent) {
    return null;
  }

  final weeks = int.tryParse(match.group(4) ?? '') ?? 0;
  final days = int.tryParse(match.group(5) ?? '') ?? 0;
  final hours = int.tryParse(match.group(6) ?? '') ?? 0;
  final minutes = int.tryParse(match.group(7) ?? '') ?? 0;
  final seconds = double.tryParse(match.group(8) ?? '') ?? 0;

  final total = Duration(
    days: weeks * 7 + days,
    hours: hours,
    minutes: minutes,
    microseconds: (seconds * Duration.microsecondsPerSecond).round(),
  );

  return match.group(1) == '-' ? -total : total;
}

/// `fromJson` hook for the generated models.
Duration? durationFromJson(Object? value) =>
    value is String ? parseIso8601Duration(value) : null;
