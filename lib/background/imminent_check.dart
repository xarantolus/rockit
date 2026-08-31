/// Deciding when a subscribed launch needs looking at again close to liftoff.
library;

import 'package:rockit/background/reminders.dart';

export 'package:rockit/background/reminders.dart' show reminderOffsets;

/// How long before a reminder its check runs.
///
/// It has to land while the reminder can still be moved or cancelled, or a
/// launch that slipped announces "5 minutes" and is corrected afterwards.
const checkLead = Duration(minutes: 1);

/// Nearer than this, a launch is worth checks of its own; further out the
/// hourly batched refresh schedules them when it comes into range.
const imminentWindow = Duration(hours: 6);

/// How long to wait before each near-liftoff check of [net], soonest first,
/// each carrying the reminder it guards.
///
/// A reminder already in the past gets no check, which is what stops work
/// being scheduled in the past for a launch picked up late.
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
/// piling them up.
String imminentCheckTaskName(String launchId, Duration offset) =>
    "update:launch:$launchId:check:${offset.inMinutes}";

/// Every name [imminentCheckDelays] could produce, for cancelling them all.
Iterable<String> imminentCheckTaskNames(String launchId) =>
    reminderOffsets.map((offset) => imminentCheckTaskName(launchId, offset));
