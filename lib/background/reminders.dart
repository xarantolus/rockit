/// When a subscription's reminders fire, and how each describes itself.
///
/// One list, because three things depend on it agreeing with itself: the
/// launch reminders, the event reminders, and the near-liftoff checks that
/// exist to correct a reminder before it goes out.
library;

const reminders = <({Duration before, String label})>[
  (before: Duration(hours: 1), label: "one hour"),
  (before: Duration(minutes: 15), label: "15 minutes"),
  (before: Duration(minutes: 5), label: "5 minutes"),
];

/// Just the times, for callers that do not need the wording.
List<Duration> get reminderOffsets =>
    reminders.map((r) => r.before).toList(growable: false);
