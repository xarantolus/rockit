import 'package:flutter_test/flutter_test.dart';
import 'package:rockit/background/handler.dart';
import 'package:rockit/background/reminders.dart';

/// The bug this guards against: [processLaunch]/[processEvent] schedule a
/// reminder's tag and id one way, and unsubscribing has to cancel the exact
/// same tag and id to actually stop it firing. Two independently-written
/// copies of that formula are free to drift apart silently — which is
/// exactly what happened before these were pulled into one place — so what
/// matters here is that the same input always maps to the same output, not
/// the specific numbers.
void main() {
  group('BackgroundHandler.launchReminderTag/Id', () {
    test('the same launch always maps to the same tag and ids', () {
      expect(
        BackgroundHandler.launchReminderTag('abc'),
        BackgroundHandler.launchReminderTag('abc'),
      );
      expect(
        BackgroundHandler.launchReminderId('abc', 1),
        BackgroundHandler.launchReminderId('abc', 1),
      );
    });

    test('each reminder index gets its own id', () {
      final ids = [
        for (var i = 0; i < reminders.length; i++)
          BackgroundHandler.launchReminderId('abc', i),
      ];

      expect(ids.toSet(), hasLength(reminders.length));
    });

    test('different launches do not share a tag', () {
      expect(
        BackgroundHandler.launchReminderTag('abc'),
        isNot(BackgroundHandler.launchReminderTag('def')),
      );
    });
  });

  group('BackgroundHandler.eventReminderTag/Id', () {
    test('the same event always maps to the same tag and ids', () {
      expect(
        BackgroundHandler.eventReminderTag('42'),
        BackgroundHandler.eventReminderTag('42'),
      );
      expect(
        BackgroundHandler.eventReminderId('42', 2),
        BackgroundHandler.eventReminderId('42', 2),
      );
    });

    test('each reminder index gets its own id', () {
      final ids = [
        for (var i = 0; i < reminders.length; i++)
          BackgroundHandler.eventReminderId('42', i),
      ];

      expect(ids.toSet(), hasLength(reminders.length));
    });

    test('an event id that will not parse still maps deterministically', () {
      // Matches the original inline formula's `event.id ?? 0` fallback: an
      // Event with no id is unusual but the model allows it, and this must
      // not throw either way.
      expect(
        BackgroundHandler.eventReminderId('not-a-number', 0),
        BackgroundHandler.eventReminderId('not-a-number', 0),
      );
    });
  });
}
