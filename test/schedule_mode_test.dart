import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rockit/background/handler.dart';

void main() {
  group('BackgroundHandler.scheduleModeFor', () {
    test('schedules exactly when exact alarms are allowed', () {
      expect(
        BackgroundHandler.scheduleModeFor(exactAllowed: true),
        AndroidScheduleMode.exactAllowWhileIdle,
      );
    });

    test('falls back to inexact rather than not scheduling at all', () {
      // SCHEDULE_EXACT_ALARM is denied by default from Android 14 on. Asking
      // for an exact alarm without it throws exact_alarms_not_permitted and
      // registers nothing, so the user would silently get no reminder.
      expect(
        BackgroundHandler.scheduleModeFor(exactAllowed: false),
        AndroidScheduleMode.inexactAllowWhileIdle,
      );
    });
  });
}
