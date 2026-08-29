import 'package:flutter_test/flutter_test.dart';
import 'package:rockit/time/duration_label.dart';

/// Event durations from the API are hours and minutes, never days — a static
/// fire window is PT3H32M12S — so rendering them in whole days showed "0 days"
/// on every event that had one.
void main() {
  group('durationParts', () {
    test('an hours-and-minutes duration keeps both', () {
      // SpaceX Starship Booster B21 Static Fire, PT3H32M12S.
      expect(
        durationParts(const Duration(hours: 3, minutes: 32, seconds: 12)),
        [
          const DurationPart(DurationUnit.hours, 3),
          const DurationPart(DurationUnit.minutes, 32),
        ],
      );
    });

    test('seconds are dropped', () {
      expect(durationParts(const Duration(hours: 1, seconds: 59)), [
        const DurationPart(DurationUnit.hours, 1),
      ]);
    });

    test('under a minute says nothing at all', () {
      // Rather than "0 minutes".
      expect(durationParts(const Duration(seconds: 30)), isEmpty);
      expect(durationParts(Duration.zero), isEmpty);
    });

    test('a whole number of hours drops the minutes', () {
      expect(durationParts(const Duration(hours: 2)), [
        const DurationPart(DurationUnit.hours, 2),
      ]);
    });

    test('minutes alone survive', () {
      expect(durationParts(const Duration(minutes: 45)), [
        const DurationPart(DurationUnit.minutes, 45),
      ]);
    });

    test('days and hours, but not minutes', () {
      // Minutes next to days would be precision the value does not have.
      expect(durationParts(const Duration(days: 2, hours: 5, minutes: 30)), [
        const DurationPart(DurationUnit.days, 2),
        const DurationPart(DurationUnit.hours, 5),
      ]);
    });

    test('an exact number of days is just days', () {
      expect(durationParts(const Duration(days: 3)), [
        const DurationPart(DurationUnit.days, 3),
      ]);
    });

    test('never yields a zero part', () {
      for (var m = 1; m < 5000; m += 7) {
        for (final part in durationParts(Duration(minutes: m))) {
          expect(part.value, greaterThan(0), reason: '$m minutes');
        }
      }
    });
  });
}
