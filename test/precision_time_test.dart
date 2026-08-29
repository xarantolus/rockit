import 'package:flutter_test/flutter_test.dart';
import 'package:rockit/apis/launch_library/common.dart';
import 'package:rockit/time/precision_time.dart';

DatePrecision precision(String abbrev) => DatePrecision(abbrev: abbrev);

void main() {
  final someDate = DateTime.utc(2026, 8, 30, 11, 26);

  // Pinned, so these do not start failing once the wall clock passes someDate.
  final beforeIt = DateTime.utc(2026, 8, 27, 9, 0);

  group('timeDisplayFor', () {
    test('counts down only when the API knows the time', () {
      for (final abbrev in ['SEC', 'MIN', 'HR']) {
        expect(
          timeDisplayFor(someDate, precision(abbrev), now: beforeIt),
          TimeDisplay.countdown,
          reason: abbrev,
        );
      }
    });

    test('shows a plain day for day and week precision', () {
      expect(
        timeDisplayFor(someDate, precision('DAY'), now: beforeIt),
        TimeDisplay.day,
      );
      expect(
        timeDisplayFor(someDate, precision('WEEK'), now: beforeIt),
        TimeDisplay.day,
      );
    });

    test('shows a window for month, quarter and year', () {
      expect(
        timeDisplayFor(someDate, precision('M'), now: beforeIt),
        TimeDisplay.month,
      );
      expect(
        timeDisplayFor(someDate, precision('Q3'), now: beforeIt),
        TimeDisplay.quarter,
      );
      expect(
        timeDisplayFor(someDate, precision('Y'), now: beforeIt),
        TimeDisplay.year,
      );
    });

    test('treats half-years like quarters', () {
      // Both mean "some months this year".
      expect(
        timeDisplayFor(someDate, precision('H1'), now: beforeIt),
        TimeDisplay.quarter,
      );
      expect(
        timeDisplayFor(someDate, precision('H2'), now: beforeIt),
        TimeDisplay.quarter,
      );
    });

    test('matching is case insensitive', () {
      expect(
        timeDisplayFor(someDate, precision('min'), now: beforeIt),
        TimeDisplay.countdown,
      );
      expect(
        timeDisplayFor(someDate, precision('q3'), now: beforeIt),
        TimeDisplay.quarter,
      );
    });

    test('an unrecognised precision degrades to a day, never a countdown', () {
      // If the API adds a vocabulary entry, claiming less precision is the
      // safe way to be wrong.
      expect(
        timeDisplayFor(someDate, precision('FORTNIGHT'), now: beforeIt),
        TimeDisplay.day,
      );
    });

    test('no date at all is unknown', () {
      expect(
        timeDisplayFor(null, precision('MIN'), now: beforeIt),
        TimeDisplay.unknown,
      );
      expect(timeDisplayFor(null, null, now: beforeIt), TimeDisplay.unknown);
    });

    test('a response with no precision keeps the old countdown behaviour', () {
      // Cached 2.2.0 responses predate the field entirely.
      expect(
        timeDisplayFor(someDate, null, now: beforeIt),
        TimeDisplay.countdown,
      );
    });

    group('once a launch is history', () {
      final justAfter = someDate.add(const Duration(minutes: 1));
      final almostStale = someDate.add(staleAfterLaunch);
      final stale = someDate.add(staleAfterLaunch + const Duration(seconds: 1));

      test('it counts up for the first week', () {
        // "T+3h" is how you tell something launched this morning.
        expect(
          timeDisplayFor(someDate, precision('SEC'), now: justAfter),
          TimeDisplay.countdown,
        );
        expect(
          timeDisplayFor(someDate, precision('SEC'), now: almostStale),
          TimeDisplay.countdown,
        );
      });

      test('and then becomes a date', () {
        expect(
          timeDisplayFor(someDate, precision('SEC'), now: stale),
          TimeDisplay.pastDateTime,
        );
      });

      test('a precision-less cached response ages the same way', () {
        expect(
          timeDisplayFor(someDate, null, now: stale),
          TimeDisplay.pastDateTime,
        );
      });

      test('a vaguer precision keeps its own form, however old', () {
        // A month-precision launch never showed a clock, so there is nothing
        // to stop showing.
        expect(
          timeDisplayFor(someDate, precision('M'), now: stale),
          TimeDisplay.month,
        );
        expect(
          timeDisplayFor(someDate, precision('DAY'), now: stale),
          TimeDisplay.day,
        );
      });

      test('a future launch is never stale', () {
        expect(
          timeDisplayFor(someDate, precision('SEC'), now: beforeIt),
          TimeDisplay.countdown,
        );
      });
    });
  });

  group('timeBecameKnown', () {
    test('a guess turning into a clock time is worth saying', () {
      expect(timeBecameKnown(precision('M'), precision('MIN')), isTrue);
      expect(timeBecameKnown(precision('Q3'), precision('SEC')), isTrue);
      expect(timeBecameKnown(precision('Y'), precision('HR')), isTrue);
    });

    test('staying vague is not', () {
      expect(timeBecameKnown(precision('Y'), precision('M')), isFalse);
      expect(timeBecameKnown(precision('M'), precision('DAY')), isFalse);
    });

    test('staying precise is not, however much the time moves', () {
      // A launch slipping by hours is normal and would be constant noise.
      expect(timeBecameKnown(precision('MIN'), precision('SEC')), isFalse);
      expect(timeBecameKnown(precision('SEC'), precision('SEC')), isFalse);
    });

    test('going vague again is not', () {
      expect(timeBecameKnown(precision('MIN'), precision('M')), isFalse);
    });

    test('an unknown precision does not count as known', () {
      expect(timeBecameKnown(precision('FORTNIGHT'), precision('MIN')), isTrue);
      expect(
        timeBecameKnown(precision('MIN'), precision('FORTNIGHT')),
        isFalse,
      );
    });
  });

  group('quarterOf', () {
    test('maps months onto quarters', () {
      expect(quarterOf(DateTime.utc(2026, 1)), 1);
      expect(quarterOf(DateTime.utc(2026, 3)), 1);
      expect(quarterOf(DateTime.utc(2026, 4)), 2);
      expect(quarterOf(DateTime.utc(2026, 6)), 2);
      expect(quarterOf(DateTime.utc(2026, 7)), 3);
      expect(quarterOf(DateTime.utc(2026, 9)), 3);
      expect(quarterOf(DateTime.utc(2026, 10)), 4);
      expect(quarterOf(DateTime.utc(2026, 12)), 4);
    });
  });

  group('Countdown', () {
    test('splits a future gap', () {
      final c = Countdown.between(
        DateTime.utc(2026, 8, 30, 11, 26, 0),
        DateTime.utc(2026, 8, 27, 8, 13, 15),
      );

      expect(c.isPast, isFalse);
      expect(c.days, 3);
      expect(c.hours, 3);
      expect(c.minutes, 12);
      expect(c.seconds, 45);
      expect(c.clock, 'T-3d 03:12:45');
    });

    test('drops the day part when under a day', () {
      final c = Countdown.between(
        DateTime.utc(2026, 8, 27, 11, 0, 0),
        DateTime.utc(2026, 8, 27, 8, 13, 15),
      );

      expect(c.days, 0);
      expect(c.clock, 'T-02:46:45');
    });

    test('pads each part to two digits', () {
      final c = Countdown.between(
        DateTime.utc(2026, 8, 27, 8, 14, 5),
        DateTime.utc(2026, 8, 27, 8, 13, 4),
      );

      expect(c.clock, 'T-00:01:01');
    });

    test('flips to T+ once the moment has passed', () {
      final c = Countdown.between(
        DateTime.utc(2026, 8, 27, 8, 0, 0),
        DateTime.utc(2026, 8, 27, 8, 5, 30),
      );

      expect(c.isPast, isTrue);
      expect(c.minutes, 5);
      expect(c.seconds, 30);
      expect(c.clock, 'T+00:05:30');
    });

    test('is exactly zero at T-0', () {
      final at = DateTime.utc(2026, 8, 27, 8);
      final c = Countdown.between(at, at);

      expect(c.days, 0);
      expect(c.hours, 0);
      expect(c.minutes, 0);
      expect(c.seconds, 0);
      expect(c.clock, 'T-00:00:00');
    });

    test('handles a gap of many days', () {
      final c = Countdown.between(
        DateTime.utc(2027, 1, 1),
        DateTime.utc(2026, 1, 1),
      );

      expect(c.days, 365);
      expect(c.clock, 'T-365d 00:00:00');
    });
  });
}
