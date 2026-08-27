import 'package:flutter_test/flutter_test.dart';
import 'package:rockit/apis/launch_library/iso_duration.dart';

void main() {
  group('parseIso8601Duration', () {
    test('parses a pad turnaround', () {
      // Real value from the API.
      expect(
        parseIso8601Duration('P71DT7H48M8S'),
        const Duration(days: 71, hours: 7, minutes: 48, seconds: 8),
      );
    });

    test('parses a duration with no seconds component', () {
      expect(
        parseIso8601Duration('P122DT21H13M'),
        const Duration(days: 122, hours: 21, minutes: 13),
      );
    });

    test('parses a negative countdown milestone', () {
      expect(
        parseIso8601Duration('-PT18M30S'),
        const Duration(minutes: -18, seconds: -30),
      );
    });

    test('parses the smallest milestones', () {
      expect(parseIso8601Duration('-PT7S'), const Duration(seconds: -7));
      expect(parseIso8601Duration('-PT1M'), const Duration(minutes: -1));
    });

    test('parses T-0 itself', () {
      expect(parseIso8601Duration('P0D'), Duration.zero);
    });

    test('distinguishes months from minutes by position', () {
      // 5M before the T is months, which is not representable...
      expect(parseIso8601Duration('P5M'), isNull);
      // ...while after the T it is minutes.
      expect(parseIso8601Duration('PT5M'), const Duration(minutes: 5));
    });

    test('rejects years, which have no fixed length', () {
      expect(parseIso8601Duration('P1Y'), isNull);
      expect(parseIso8601Duration('P1YT1H'), isNull);
    });

    test('parses weeks', () {
      expect(parseIso8601Duration('P2W'), const Duration(days: 14));
    });

    test('parses fractional seconds', () {
      expect(
        parseIso8601Duration('PT1.5S'),
        const Duration(milliseconds: 1500),
      );
    });

    test('returns null for junk rather than throwing', () {
      for (final input in [
        null,
        '',
        'P',
        '-P',
        'nonsense',
        '71 days',
        'PT',
        'T5M',
        '2026-08-27T20:10:00Z',
      ]) {
        expect(parseIso8601Duration(input), isNull, reason: 'input: $input');
      }
    });

    test('durationFromJson only accepts strings', () {
      expect(durationFromJson('PT5M'), const Duration(minutes: 5));
      expect(durationFromJson(null), isNull);
      expect(durationFromJson(300), isNull);
      expect(durationFromJson(<String, dynamic>{}), isNull);
    });
  });
}
