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
  _watchStates();
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
}

void _watchStates() {
  group('untilNextTimelineChange', () {
    // The rows are fixed offsets; only the highlight moves. So this is the
    // only moment worth redrawing for, and a page opened before the first
    // milestone still has to be told about it — with nothing scheduled it
    // never lit up at all.
    final offsets = [
      const Duration(hours: -1),
      const Duration(minutes: -5),
      Duration.zero,
      const Duration(minutes: 9),
    ];

    test('waits for the first milestone when nothing has started', () {
      expect(
        untilNextTimelineChange(
          offsets: offsets,
          elapsed: const Duration(hours: -3),
        ),
        const Duration(hours: 2),
      );
    });

    test('waits for the next one while running', () {
      expect(
        untilNextTimelineChange(
          offsets: offsets,
          elapsed: const Duration(minutes: -30),
        ),
        const Duration(minutes: 25),
      );
    });

    test('a milestone exactly now waits for the one after it', () {
      expect(
        untilNextTimelineChange(offsets: offsets, elapsed: Duration.zero),
        const Duration(minutes: 9),
      );
    });

    test('nothing left to wait for once the last has passed', () {
      expect(
        untilNextTimelineChange(
          offsets: offsets,
          elapsed: const Duration(minutes: 9),
        ),
        isNull,
      );
      expect(
        untilNextTimelineChange(
          offsets: offsets,
          elapsed: const Duration(days: 1),
        ),
        isNull,
      );
    });

    test('an empty timeline never waits', () {
      expect(
        untilNextTimelineChange(offsets: const [], elapsed: Duration.zero),
        isNull,
      );
    });

    test('the wait is always positive', () {
      for (var m = -70; m < 15; m++) {
        final until = untilNextTimelineChange(
          offsets: offsets,
          elapsed: Duration(minutes: m),
        );
        if (until != null) {
          expect(until, greaterThan(Duration.zero));
        }
      }
    });
  });

  group('timelineOffsetLabel', () {
    test('drops a trailing zero rather than writing "5m 0s"', () {
      expect(timelineOffsetLabel(const Duration(minutes: 5)), 'T+5m');
      expect(timelineOffsetLabel(const Duration(minutes: -5)), 'T-5m');
      expect(timelineOffsetLabel(const Duration(hours: 1)), 'T+1h');
      expect(timelineOffsetLabel(const Duration(hours: -1)), 'T-1h');
    });

    test('keeps both parts when the smaller one is not zero', () {
      expect(
        timelineOffsetLabel(const Duration(hours: -1, minutes: -30)),
        'T-1h 30m',
      );
      expect(
        timelineOffsetLabel(const Duration(minutes: 5, seconds: 30)),
        'T+5m 30s',
      );
    });

    test('under a minute is just seconds', () {
      expect(timelineOffsetLabel(const Duration(seconds: 45)), 'T+45s');
      expect(timelineOffsetLabel(const Duration(seconds: -45)), 'T-45s');
    });

    test('liftoff is T-0', () {
      expect(timelineOffsetLabel(Duration.zero), 'T-0');
    });
  });
}
