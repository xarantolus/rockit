import 'package:flutter_test/flutter_test.dart';
import 'package:rockit/background/imminent_check.dart';

/// Subscriptions refresh in one batched request an hour, which is fine for a
/// launch days out and useless for one about to fly — the alternative, making
/// every subscription tick quarter-hourly, is the cost problem that batching
/// was meant to fix.
///
/// So each reminder gets a check just before it. That ordering is the whole
/// point: a launch that has slipped an hour must not announce "5 minutes" and
/// be corrected afterwards.
void main() {
  final now = DateTime(2026, 9, 12, 12, 0);

  List<({Duration delay, Duration offset})> checks(Duration until) =>
      imminentCheckDelays(now.add(until), now);

  List<Duration> delays(Duration until) =>
      checks(until).map((c) => c.delay).toList();

  group('imminentCheckDelays', () {
    test('nothing to schedule without a date', () {
      expect(imminentCheckDelays(null, now), isEmpty);
    });

    test('nothing beyond the window, or once the launch has gone', () {
      expect(checks(const Duration(hours: 7)), isEmpty);
      expect(checks(const Duration(days: 3)), isEmpty);
      expect(checks(Duration.zero), isEmpty);
      expect(checks(const Duration(seconds: -1)), isEmpty);
    });

    test('one check per reminder, soonest first', () {
      final due = checks(const Duration(hours: 3));

      expect(due, hasLength(reminderOffsets.length));
      expect(
        due.map((c) => c.offset),
        // Sorted by when they run, so the hour reminder's check comes first.
        [
          const Duration(hours: 1),
          const Duration(minutes: 15),
          const Duration(minutes: 5),
        ],
      );
      expect(due.map((c) => c.delay), [
        const Duration(hours: 1, minutes: 59),
        const Duration(hours: 2, minutes: 44),
        const Duration(hours: 2, minutes: 54),
      ]);
    });

    test('every check lands before the reminder it guards', () {
      for (var m = 1; m <= 6 * 60; m++) {
        final until = Duration(minutes: m);

        for (final check in checks(until)) {
          expect(
            check.delay,
            lessThan(until - check.offset),
            reason: 'a check for T-${check.offset.inMinutes}m at T-${m}m',
          );
        }
      }
    });

    test('a reminder already past gets no check', () {
      // Ten minutes out: the hour and fifteen-minute reminders have gone, so
      // only the five-minute one is still worth guarding.
      expect(delays(const Duration(minutes: 10)), [const Duration(minutes: 4)]);

      // Inside the last reminder there is nothing left to correct.
      expect(checks(const Duration(minutes: 3)), isEmpty);
    });

    test('a check is never scheduled in the past', () {
      for (var m = 1; m <= 6 * 60; m++) {
        for (final check in checks(Duration(minutes: m))) {
          expect(check.delay, greaterThanOrEqualTo(Duration.zero));
        }
      }
    });

    test('the window edge is still in', () {
      expect(checks(imminentWindow), isNotEmpty);
    });
  });

  group('imminentCheckTaskName', () {
    test('is distinct per reminder, so they do not replace each other', () {
      final names = imminentCheckTaskNames('abc').toSet();

      expect(names, hasLength(reminderOffsets.length));
    });

    test('covers every name the delays can produce', () {
      final possible = imminentCheckTaskNames('abc').toSet();

      for (final check in checks(const Duration(hours: 3))) {
        expect(possible, contains(imminentCheckTaskName('abc', check.offset)));
      }
    });

    test('is namespaced per launch', () {
      expect(
        imminentCheckTaskName('abc', const Duration(minutes: 5)),
        isNot(imminentCheckTaskName('def', const Duration(minutes: 5))),
      );
    });
  });
}
