import 'package:flutter_test/flutter_test.dart';
import 'package:rockit/background/handler.dart';

/// A new update and a time change used to fire as two separate notifications
/// for what a subscriber reads as one event. They're bundled into one now,
/// which is what [BackgroundHandler.describeTimeChangeLine] picks the
/// wording for: a short fragment when it is sitting next to update lines, a
/// full sentence when the time change is the only thing being reported.
void main() {
  group('BackgroundHandler.describeTimeChangeLine', () {
    test('names the time explicitly when bundled with updates', () {
      // A bare "Now: X" next to an unrelated update comment does not say
      // what changed.
      expect(
        BackgroundHandler.describeTimeChangeLine(
          noun: 'launch',
          time: 'Thu 2 Oct, 14:00',
          wasUnknown: false,
          short: true,
        ),
        'New launch time: Thu 2 Oct, 14:00',
      );
    });

    test('short wording ignores whether the time was previously unknown', () {
      // The bundled fragment has no room for that distinction, and it does
      // not need it: it is already clearly a "here is the time" statement.
      expect(
        BackgroundHandler.describeTimeChangeLine(
          noun: 'event',
          time: 'Thu 2 Oct, 14:00',
          wasUnknown: true,
          short: true,
        ),
        'New event time: Thu 2 Oct, 14:00',
      );
    });

    test(
      'a time appearing for the first time reads as a fact, not an edit',
      () {
        expect(
          BackgroundHandler.describeTimeChangeLine(
            noun: 'launch',
            time: 'Thu 2 Oct, 14:00',
            wasUnknown: true,
            short: false,
          ),
          'The launch time is now Thu 2 Oct, 14:00',
        );
      },
    );

    test('a time that was already known reads as a change', () {
      expect(
        BackgroundHandler.describeTimeChangeLine(
          noun: 'launch',
          time: 'Thu 2 Oct, 14:00',
          wasUnknown: false,
          short: false,
        ),
        'The launch time changed to Thu 2 Oct, 14:00',
      );
    });

    test('launch and event use the same wording, only the noun differs', () {
      final launch = BackgroundHandler.describeTimeChangeLine(
        noun: 'launch',
        time: 'Thu 2 Oct, 14:00',
        wasUnknown: false,
        short: false,
      );
      final event = BackgroundHandler.describeTimeChangeLine(
        noun: 'event',
        time: 'Thu 2 Oct, 14:00',
        wasUnknown: false,
        short: false,
      );

      expect(launch.replaceFirst('launch', 'event'), event);
    });
  });
}
