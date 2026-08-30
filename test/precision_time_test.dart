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

    test('covers every abbreviation the API defines', () {
      // The full list is /2.3.0/config/net_precisions/ — seventeen of them.
      // These are the ones that used to fall through to "unknown", which
      // renders as a precise calendar day: a decade shown as a Wednesday.
      expect(
        timeDisplayFor(someDate, precision('WK'), now: beforeIt),
        TimeDisplay.day,
      );
      expect(
        timeDisplayFor(someDate, precision('AM'), now: beforeIt),
        TimeDisplay.day,
      );
      expect(
        timeDisplayFor(someDate, precision('PM'), now: beforeIt),
        TimeDisplay.day,
      );
      expect(
        timeDisplayFor(someDate, precision('FY'), now: beforeIt),
        TimeDisplay.year,
      );
      expect(
        timeDisplayFor(someDate, precision('DEC'), now: beforeIt),
        TimeDisplay.decade,
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
      // The field is absent whenever the API has not set it.
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

  group('displayedTimeKey', () {
    // The rule a subscriber notification hangs on: a key change is exactly a
    // change on screen, so it must not move for anything the user cannot see.
    final at = DateTime(2026, 9, 12, 14, 30);

    String? key(DateTime? d, String? abbrev) =>
        displayedTimeKey(d, abbrev == null ? null : precision(abbrev));

    test('no date has no key', () {
      expect(key(null, 'MIN'), isNull);
    });

    test('a countdown is identical down to the minute', () {
      expect(key(at, 'MIN'), key(at, 'SEC'));
      expect(key(at, 'MIN'), key(at, 'HR'));
    });

    test('seconds are below what a countdown key tracks', () {
      expect(
        key(DateTime(2026, 9, 12, 14, 30, 5), 'MIN'),
        key(DateTime(2026, 9, 12, 14, 30, 55), 'MIN'),
      );
    });

    test('a minute of slip is a change at minute precision', () {
      expect(key(at, 'MIN'), isNot(key(DateTime(2026, 9, 12, 14, 31), 'MIN')));
    });

    test('the same slip is invisible at day precision', () {
      expect(key(at, 'DAY'), key(DateTime(2026, 9, 12, 23, 59), 'DAY'));
    });

    test('moving a day shows at day precision', () {
      expect(key(at, 'DAY'), isNot(key(DateTime(2026, 9, 13), 'DAY')));
    });

    test('a month-precision launch may roam its whole month unseen', () {
      expect(key(DateTime(2026, 9, 1), 'M'), key(DateTime(2026, 9, 30), 'M'));
      expect(
        key(DateTime(2026, 9, 30), 'M'),
        isNot(key(DateTime(2026, 10, 1), 'M')),
      );
    });

    test('quarters group by quarter, not month', () {
      expect(key(DateTime(2026, 7, 1), 'Q3'), key(DateTime(2026, 9, 30), 'Q3'));
      expect(
        key(DateTime(2026, 9, 30), 'Q3'),
        isNot(key(DateTime(2026, 10, 1), 'Q3')),
      );
    });

    test('a year and a decade widen further still', () {
      expect(key(DateTime(2026, 1, 1), 'Y'), key(DateTime(2026, 12, 31), 'Y'));
      expect(
        key(DateTime(2030, 1, 1), 'DEC'),
        key(DateTime(2039, 12, 31), 'DEC'),
      );
      expect(
        key(DateTime(2039, 12, 31), 'DEC'),
        isNot(key(DateTime(2040, 1, 1), 'DEC')),
      );
    });

    test('a precision change is a change, both ways', () {
      // Going vague is as visible as becoming precise: "NET October" replaces
      // a clock time on the card either way round.
      expect(key(at, 'MIN'), isNot(key(at, 'M')));
      expect(key(at, 'M'), isNot(key(at, 'MIN')));
    });

    test('a week renders as a day, and an unknown precision does too', () {
      expect(key(at, 'WK'), key(at, 'DAY'));
      expect(key(at, 'FORTNIGHT'), key(at, 'DAY'));
    });

    test('a missing precision is treated as a clock time', () {
      expect(key(at, null), key(at, 'MIN'));
    });
  });

  group('untilNextLocalMidnight', () {
    // Every friendly label is relative to today, so this is when a screen left
    // open has to look again. A card saying "Tomorrow, 11:26" otherwise still
    // says it after midnight, when it means today.
    test('counts the rest of the day', () {
      expect(
        untilNextLocalMidnight(DateTime(2026, 8, 30, 23, 30)),
        const Duration(minutes: 30),
      );
      expect(
        untilNextLocalMidnight(DateTime(2026, 8, 30, 0, 0, 1)),
        const Duration(hours: 24) - const Duration(seconds: 1),
      );
    });

    test('is a whole day exactly at midnight, never zero', () {
      expect(
        untilNextLocalMidnight(DateTime(2026, 8, 30)),
        const Duration(hours: 24),
      );
    });

    test('rolls over a month and a year', () {
      expect(
        untilNextLocalMidnight(DateTime(2026, 8, 31, 23, 0)),
        const Duration(hours: 1),
      );
      expect(
        untilNextLocalMidnight(DateTime(2026, 12, 31, 22, 15)),
        const Duration(hours: 1, minutes: 45),
      );
    });

    test('handles a leap day', () {
      expect(
        untilNextLocalMidnight(DateTime(2028, 2, 28, 23, 59)),
        const Duration(minutes: 1),
      );
    });

    test('is always positive', () {
      for (var h = 0; h < 24; h++) {
        expect(
          untilNextLocalMidnight(DateTime(2026, 8, 30, h, 37)),
          greaterThan(Duration.zero),
        );
      }
    });
  });
}
