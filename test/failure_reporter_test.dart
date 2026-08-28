import 'package:flutter_test/flutter_test.dart';
import 'package:rockit/util/failure_reporter.dart';

/// The subscriptions listing reloads every time the user returns from a detail
/// page, so "did anything fail" is asked over and over for the same failures.
/// This is the bit that decides whether it is worth saying anything.
void main() {
  group('FailureReporter', () {
    test('says nothing when nothing failed', () {
      expect(FailureReporter().take({}), isEmpty);
    });

    test('reports a failure the first time', () {
      expect(FailureReporter().take({'launch:a'}), {'launch:a'});
    });

    test('stays quiet when the same thing fails again', () {
      final reporter = FailureReporter();

      expect(reporter.take({'launch:a'}), {'launch:a'});
      expect(reporter.take({'launch:a'}), isEmpty);
      expect(reporter.take({'launch:a'}), isEmpty);
    });

    test('a newly broken subscription is still worth saying', () {
      final reporter = FailureReporter();
      reporter.take({'launch:a'});

      // Only the new one: the old failure has already been mentioned.
      expect(reporter.take({'launch:a', 'event:b'}), {'event:b'});
    });

    test('something that recovers is news again if it breaks later', () {
      final reporter = FailureReporter();

      expect(reporter.take({'launch:a'}), {'launch:a'});
      expect(reporter.take({}), isEmpty);
      expect(reporter.take({'launch:a'}), {'launch:a'});
    });

    test('a partial recovery does not un-report the rest', () {
      final reporter = FailureReporter();
      reporter.take({'launch:a', 'event:b'});

      expect(reporter.take({'event:b'}), isEmpty);
      expect(reporter.take({'launch:a', 'event:b'}), {'launch:a'});
    });
  });
}
