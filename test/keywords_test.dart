import 'package:flutter_test/flutter_test.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/background/keywords.dart';

/// These rules decide, without asking, that someone is subscribed to something
/// and gets notified about it. The one that matters most is that a launch the
/// user has unsubscribed from never comes back.
void main() {
  final now = DateTime(2026, 9, 12, 12, 0);

  Launch launch({
    required String id,
    String name = 'Starship | Flight 15',
    String? rocket,
    Duration ahead = const Duration(days: 30),
    String precision = 'MIN',
  }) {
    return Launch(
      id: id,
      name: name,
      net: now.add(ahead),
      netPrecision: DatePrecision(abbrev: precision),
      rocket: rocket == null
          ? null
          : Rocket(configuration: RocketConfiguration(fullName: rocket)),
    );
  }

  List<String> pick(
    List<Launch> launches,
    List<LaunchKeyword> keywords, {
    Set<String> subscribed = const {},
    Set<String> declined = const {},
  }) {
    return launchesToAutoSubscribe(
      launches: launches,
      keywords: keywords,
      subscribed: subscribed,
      declined: declined,
      now: now,
    ).map((l) => l.id!).toList();
  }

  group('keywordMatches', () {
    const starship = LaunchKeyword(text: 'starship');

    test('matches the launch name, whatever the case', () {
      expect(keywordMatches(starship, launch(id: 'a')), isTrue);
      expect(
        keywordMatches(const LaunchKeyword(text: 'STARSHIP'), launch(id: 'a')),
        isTrue,
      );
    });

    test('matches the rocket when the name does not say it', () {
      final l = launch(id: 'a', name: 'Transporter-15', rocket: 'Falcon 9');

      expect(keywordMatches(const LaunchKeyword(text: 'falcon'), l), isTrue);
      expect(keywordMatches(starship, l), isFalse);
    });

    test('does not match the provider', () {
      // "spacex" as a keyword would otherwise mean every SpaceX launch there
      // is, which is the whole listing rather than a watchlist.
      final l = launch(id: 'a', name: 'Transporter-15', rocket: 'Falcon 9');

      expect(keywordMatches(const LaunchKeyword(text: 'spacex'), l), isFalse);
    });

    test('an empty keyword matches nothing', () {
      expect(
        keywordMatches(const LaunchKeyword(text: '   '), launch(id: 'a')),
        isFalse,
      );
    });
  });

  group('launchesToAutoSubscribe', () {
    const starship = LaunchKeyword(text: 'starship');

    test('picks a match inside the window', () {
      expect(pick([launch(id: 'a')], [starship]), ['a']);
    });

    test('never picks something the user unsubscribed from', () {
      // The invariant the feature rests on: unsubscribing is final, and no
      // keyword may undo it.
      expect(pick([launch(id: 'a')], [starship], declined: {'a'}), isEmpty);
    });

    test('skips what is already subscribed, so it cannot notify twice', () {
      expect(pick([launch(id: 'a')], [starship], subscribed: {'a'}), isEmpty);
    });

    test('respects each keyword its own window', () {
      final far = launch(id: 'a', ahead: const Duration(days: 200));

      expect(pick([far], [starship]), isEmpty);
      expect(pick([far], [const LaunchKeyword(text: 'starship', days: 365)]), [
        'a',
      ]);
    });

    test('the window edge is in, past it is not', () {
      expect(
        pick([launch(id: 'a', ahead: const Duration(days: 180))], [starship]),
        ['a'],
      );
      expect(
        pick([launch(id: 'a', ahead: const Duration(days: 181))], [starship]),
        isEmpty,
      );
    });

    test('ignores launches that have already gone', () {
      expect(
        pick([launch(id: 'a', ahead: const Duration(days: -1))], [starship]),
        isEmpty,
      );
      expect(
        pick([launch(id: 'a', ahead: Duration.zero)], [starship]),
        isEmpty,
      );
    });

    test('a date the API only guesses at is not enough', () {
      // "NET October" is not a time to set reminders against.
      for (final vague in ['M', 'Q3', 'Y', 'WK', 'DEC']) {
        expect(
          pick([launch(id: 'a', precision: vague)], [starship]),
          isEmpty,
          reason: vague,
        );
      }

      for (final firm in ['SEC', 'MIN', 'HR', 'DAY']) {
        expect(pick([launch(id: 'a', precision: firm)], [starship]), [
          'a',
        ], reason: firm);
      }
    });

    test('a missing precision counts as not knowing', () {
      final l = Launch(
        id: 'a',
        name: 'Starship',
        net: now.add(const Duration(days: 3)),
      );

      expect(pick([l], [starship]), isEmpty);
    });

    test('no keywords means no subscriptions', () {
      expect(pick([launch(id: 'a')], []), isEmpty);
      expect(
        pick([launch(id: 'a')], [const LaunchKeyword(text: '  ')]),
        isEmpty,
      );
    });

    test('a launch matching two keywords is picked once', () {
      final picked = pick(
        [launch(id: 'a', rocket: 'Starship')],
        [starship, const LaunchKeyword(text: 'flight')],
      );

      expect(picked, ['a']);
    });

    test('picks only the matches out of a mixed listing', () {
      final launches = [
        launch(id: 'a'),
        launch(id: 'b', name: 'Falcon 9 | Starlink 15-23', rocket: 'Falcon 9'),
        launch(id: 'c', name: 'Electron | StriX'),
      ];

      expect(pick(launches, [starship]), ['a']);
      expect(pick(launches, [const LaunchKeyword(text: 'falcon')]), ['b']);
    });
  });

  group('LaunchKeyword storage', () {
    test('survives a round trip', () {
      const keywords = [
        LaunchKeyword(text: 'starship', days: 365),
        LaunchKeyword(text: 'Electron'),
      ];

      expect(LaunchKeyword.decode(LaunchKeyword.encode(keywords)), keywords);
    });

    test('defaults the window when it is missing or nonsense', () {
      final decoded = LaunchKeyword.decode(
        '[{"text":"a"},{"text":"b","days":0},{"text":"c","days":"x"}]',
      );

      expect(
        decoded.map((k) => k.days),
        everyElement(LaunchKeyword.defaultDays),
      );
    });

    test('drops entries it cannot read rather than throwing', () {
      expect(LaunchKeyword.decode('not json'), isEmpty);
      expect(LaunchKeyword.decode('{"text":"a"}'), isEmpty);
      expect(LaunchKeyword.decode('[1,2,{"text":""},{"text":"ok"}]'), [
        const LaunchKeyword(text: 'ok'),
      ]);
    });

    test('nothing stored is no keywords', () {
      expect(LaunchKeyword.decode(null), isEmpty);
      expect(LaunchKeyword.decode(''), isEmpty);
    });
  });
}
