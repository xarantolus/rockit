import 'package:flutter_test/flutter_test.dart';
import 'package:rockit/time/timeline_progress.dart';

/// A real Falcon 9 style countdown, in offsets from T-0.
const countdown = [
  Duration(minutes: -35),
  Duration(minutes: -7),
  Duration(seconds: -60),
  Duration(seconds: -3),
  Duration.zero,
  Duration(minutes: 2, seconds: 12),
];

void main() {
  group('activeTimelineIndex', () {
    test('nothing is active before the first milestone', () {
      expect(
        activeTimelineIndex(
          offsets: countdown,
          elapsed: const Duration(hours: -2),
        ),
        isNull,
      );
    });

    test('an entry becomes active exactly at its offset', () {
      expect(
        activeTimelineIndex(
          offsets: countdown,
          elapsed: const Duration(minutes: -35),
        ),
        0,
      );
    });

    test('stays active until the next one starts', () {
      expect(
        activeTimelineIndex(
          offsets: countdown,
          elapsed: const Duration(minutes: -20),
        ),
        0,
      );
      expect(
        activeTimelineIndex(
          offsets: countdown,
          elapsed: const Duration(seconds: -421),
        ),
        0,
      );
      // One second later the next milestone owns it.
      expect(
        activeTimelineIndex(
          offsets: countdown,
          elapsed: const Duration(minutes: -7),
        ),
        1,
      );
    });

    test('T-0 itself activates the liftoff entry', () {
      expect(
        activeTimelineIndex(offsets: countdown, elapsed: Duration.zero),
        4,
      );
    });

    test('the last entry is never highlighted', () {
      // The API gives no end time for it, so highlighting would mean inventing
      // one — and it would stay lit forever.
      expect(
        activeTimelineIndex(
          offsets: countdown,
          elapsed: const Duration(minutes: 2, seconds: 12),
        ),
        isNull,
      );
      expect(
        activeTimelineIndex(
          offsets: countdown,
          elapsed: const Duration(days: 400),
        ),
        isNull,
      );
    });

    test('a single entry is never highlighted', () {
      expect(
        activeTimelineIndex(
          offsets: const [Duration.zero],
          elapsed: Duration.zero,
        ),
        isNull,
      );
    });

    test('an empty timeline is never highlighted', () {
      expect(
        activeTimelineIndex(offsets: const [], elapsed: Duration.zero),
        isNull,
      );
    });

    test('handles a timeline entirely after T-0', () {
      // Some launches only describe the ascent, e.g. H3 / MMX.
      const ascent = [
        Duration.zero,
        Duration(minutes: 1, seconds: 56),
        Duration(minutes: 4, seconds: 52),
      ];

      expect(
        activeTimelineIndex(
          offsets: ascent,
          elapsed: const Duration(minutes: 1),
        ),
        0,
      );
      expect(
        activeTimelineIndex(
          offsets: ascent,
          elapsed: const Duration(minutes: 3),
        ),
        1,
      );
      expect(
        activeTimelineIndex(
          offsets: ascent,
          elapsed: const Duration(minutes: 5),
        ),
        isNull,
      );
    });
  });

  group('timelineIsRunning', () {
    test('is false long before and long after', () {
      expect(
        timelineIsRunning(
          offsets: countdown,
          elapsed: const Duration(days: -3),
        ),
        isFalse,
      );
      expect(
        timelineIsRunning(offsets: countdown, elapsed: const Duration(days: 3)),
        isFalse,
      );
    });

    test('is true between the first and last milestone', () {
      expect(
        timelineIsRunning(offsets: countdown, elapsed: Duration.zero),
        isTrue,
      );
      expect(
        timelineIsRunning(
          offsets: countdown,
          elapsed: const Duration(minutes: -35),
        ),
        isTrue,
      );
    });

    test('an empty timeline never runs', () {
      expect(
        timelineIsRunning(offsets: const [], elapsed: Duration.zero),
        isFalse,
      );
    });
  });
}
