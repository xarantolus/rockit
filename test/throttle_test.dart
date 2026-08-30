import 'package:flutter_test/flutter_test.dart';
import 'package:rockit/apis/launch_library/throttle.dart';

/// This decides how many requests a background job may spend, so getting it
/// wrong either wastes the user's budget or leaves the app throttled when they
/// next open it.
void main() {
  _untilLimitClears();
  ApiThrottle at({int? limit = 15, int? used = 0}) =>
      ApiThrottle(yourRequestLimit: limit, currentUse: used);

  group('requestsUntilHalfSpent', () {
    test('a fresh budget leaves half of it available', () {
      expect(at(used: 0).requestsUntilHalfSpent, 7);
    });

    test('what the user has already spent comes off the top', () {
      expect(at(used: 3).requestsUntilHalfSpent, 4);
      expect(at(used: 6).requestsUntilHalfSpent, 1);
    });

    test('nothing is left once half is gone', () {
      expect(at(used: 7).requestsUntilHalfSpent, 0);
    });

    test('an exhausted budget never asks for more', () {
      // Negative would read as "spend this many" if a caller compared wrongly.
      expect(at(used: 15).requestsUntilHalfSpent, lessThanOrEqualTo(0));
      expect(at(used: 99).requestsUntilHalfSpent, lessThanOrEqualTo(0));
    });

    test('a missing or nonsense limit spends nothing', () {
      expect(at(limit: null).requestsUntilHalfSpent, 0);
      expect(at(limit: 0).requestsUntilHalfSpent, 0);
      expect(at(limit: -5).requestsUntilHalfSpent, 0);
    });

    test('a larger budget scales', () {
      // The live endpoint has reported other limits than 15 before.
      expect(
        ApiThrottle(
          yourRequestLimit: 210,
          currentUse: 33,
        ).requestsUntilHalfSpent,
        72,
      );
    });

    test('parses what the endpoint actually returns', () {
      final t = ApiThrottle.fromJson(const {
        "your_request_limit": 15,
        "limit_frequency_secs": 3600,
        "current_use": 15,
        "next_use_secs": 1631,
        "ident": "188.101.224.20",
      });

      expect(t.yourRequestLimit, 15);
      expect(t.currentUse, 15);
      expect(t.nextUseSecs, 1631);
      expect(t.ident, "188.101.224.20");
      expect(t.requestsUntilHalfSpent, lessThanOrEqualTo(0));
    });
  });
}

void _untilLimitClears() {
  group('untilLimitClears', () {
    // Rounded up, because "come back in 0 minutes" helps nobody.
    test('rounds up to a whole minute', () {
      expect(
        const ApiThrottle(nextUseSecs: 61).untilLimitClears,
        const Duration(minutes: 2),
      );
      expect(
        const ApiThrottle(nextUseSecs: 60).untilLimitClears,
        const Duration(minutes: 1),
      );
      expect(
        const ApiThrottle(nextUseSecs: 1).untilLimitClears,
        const Duration(minutes: 1),
      );
    });

    test('is null when there is nothing to wait for', () {
      expect(const ApiThrottle().untilLimitClears, isNull);
      expect(const ApiThrottle(nextUseSecs: 0).untilLimitClears, isNull);
      expect(const ApiThrottle(nextUseSecs: -5).untilLimitClears, isNull);
    });

    test('handles a long wait', () {
      expect(
        const ApiThrottle(nextUseSecs: 1631).untilLimitClears,
        const Duration(minutes: 28),
      );
    });
  });
}
