import 'package:flutter_test/flutter_test.dart';
import 'package:rockit/util/relative_time.dart';

void main() {
  final now = DateTime.utc(2026, 8, 27, 12, 0, 0);

  RelativeTime ago(Duration d) => relativeTime(now.subtract(d), now);

  group('relativeTime', () {
    test('anything under a minute is just now', () {
      expect(ago(Duration.zero), const RelativeTime(RelativeUnit.justNow));
      expect(
        ago(const Duration(seconds: 59)),
        const RelativeTime(RelativeUnit.justNow),
      );
    });

    test('minutes up to an hour', () {
      expect(
        ago(const Duration(minutes: 1)),
        const RelativeTime(RelativeUnit.minutes, 1),
      );
      expect(
        ago(const Duration(minutes: 59)),
        const RelativeTime(RelativeUnit.minutes, 59),
      );
    });

    test('hours up to a day', () {
      expect(
        ago(const Duration(minutes: 60)),
        const RelativeTime(RelativeUnit.hours, 1),
      );
      expect(
        ago(const Duration(hours: 23, minutes: 59)),
        const RelativeTime(RelativeUnit.hours, 23),
      );
    });

    test('days up to a week', () {
      expect(
        ago(const Duration(hours: 24)),
        const RelativeTime(RelativeUnit.days, 1),
      );
      expect(
        ago(const Duration(days: 6, hours: 23)),
        const RelativeTime(RelativeUnit.days, 6),
      );
    });

    test('older than a week falls back to an absolute date', () {
      // "23 days ago" is harder to place than a real date.
      expect(
        ago(const Duration(days: 7)),
        const RelativeTime(RelativeUnit.absolute),
      );
      expect(
        ago(const Duration(days: 400)),
        const RelativeTime(RelativeUnit.absolute),
      );
    });

    test('rounds down rather than up', () {
      // 90 minutes is "1 hour ago", not 2.
      expect(
        ago(const Duration(minutes: 90)),
        const RelativeTime(RelativeUnit.hours, 1),
      );
    });

    test('a timestamp slightly in the future reads as just now', () {
      // Some news sites publish with a clock a little ahead.
      expect(
        relativeTime(now.add(const Duration(minutes: 3)), now),
        const RelativeTime(RelativeUnit.justNow),
      );
    });
  });
}
