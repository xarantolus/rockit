/// Joins callers that ask for the same thing while it is already running.
///
/// Two screens wanting the same URL at the same moment — which is exactly what
/// the news prefetch and the news tab do on a cold start — would otherwise
/// each spend a request, and the Launch Library allows only fifteen an hour.
///
/// [inFlight] is the caller's own map, so unrelated request kinds cannot
/// collide. The entry is removed once the work settles, successfully or not,
/// so a failure is never cached as a permanent answer.
Future<T> coalesce<T>(
  Map<String, Future<T>> inFlight,
  String key,
  Future<T> Function() start,
) {
  final existing = inFlight[key];
  if (existing != null) {
    return existing;
  }

  final work = start();
  inFlight[key] = work;

  return work.whenComplete(() {
    // Only drop our own entry: a later call may already have replaced it.
    if (identical(inFlight[key], work)) {
      inFlight.remove(key);
    }
  });
}
