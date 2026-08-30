/// Deciding when a subscribed launch needs looking at again close to liftoff.
library;

/// When the reminders fire, and therefore what the checks are for.
///
/// Kept in step with `processLaunch`'s own list; a check exists for each of
/// these and nothing else.
const reminderOffsets = [
  Duration(hours: 1),
  Duration(minutes: 15),
  Duration(minutes: 5),
];

/// How long before a reminder its check runs.
///
/// The point of the check is to catch a slip *before* the reminder goes out.
/// A launch that has moved an hour should not announce "5 minutes" first and
/// be corrected afterwards, so the refresh has to land while there is still
/// time to cancel or move it — but only just, or it is looking at a stale
/// answer by the time the reminder is due.
const checkLead = Duration(minutes: 1);

/// Below this, a launch is close enough to be worth checks of its own. Further
/// out, the hourly batched refresh is enough and will schedule these when the
/// launch comes into range.
const imminentWindow = Duration(hours: 6);

/// How long to wait before each near-liftoff check of [net], soonest first.
///
/// Empty for a launch with no date, one already gone, and one still further
/// out than [imminentWindow].
///
/// A reminder that is already in the past gets no check — there is nothing
/// left to correct — which is also what keeps this from scheduling work in the
/// past when a launch is picked up late.
/// Each carries the reminder it guards, which is what names its task.
List<({Duration delay, Duration offset})> imminentCheckDelays(
  DateTime? net,
  DateTime now, {
  Duration window = imminentWindow,
}) {
  if (net == null) {
    return const [];
  }

  final until = net.difference(now);

  if (until <= Duration.zero || until > window) {
    return const [];
  }

  final due = <({Duration delay, Duration offset})>[];

  for (final offset in reminderOffsets) {
    final delay = until - offset - checkLead;

    if (!delay.isNegative) {
      due.add((delay: delay, offset: offset));
    }
  }

  due.sort((a, b) => a.delay.compareTo(b.delay));

  return due;
}

/// A stable name per check, so registering one twice replaces it rather than
/// piling them up, and unsubscribing can cancel every one.
String imminentCheckTaskName(String launchId, Duration offset) =>
    "update:launch:$launchId:check:${offset.inMinutes}";

/// Every name [imminentCheckDelays] could have produced for [launchId].
Iterable<String> imminentCheckTaskNames(String launchId) =>
    reminderOffsets.map((offset) => imminentCheckTaskName(launchId, offset));
