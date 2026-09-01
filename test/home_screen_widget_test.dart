import 'package:flutter_test/flutter_test.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/background/home_screen_widget.dart';
import 'package:rockit/time/precision_time.dart';

/// The widget is read at a glance and never opened, so a row that is out of
/// date is worse here than anywhere else in the app: nothing prompts the user
/// to doubt it.
void main() {
  final now = DateTime(2026, 9, 12, 12, 0);

  String fakeFormat(DateTime at, DatePrecision? precision) =>
      "${at.hour}:${at.minute.toString().padLeft(2, '0')}";

  Launch launch(String id, Duration ahead, {String name = 'A launch'}) =>
      Launch(
        id: id,
        name: name,
        net: now.add(ahead),
        netPrecision: const DatePrecision(abbrev: 'MIN'),
      );

  Event event(int id, Duration ahead, {String name = 'An event'}) =>
      Event(id: id, name: name, date: now.add(ahead));

  List<WidgetEntry> pick({
    List<Launch> launches = const [],
    List<Event> events = const [],
    int limit = homeWidgetRows,
  }) => nextEntries(
    launches: launches,
    events: events,
    now: now,
    format: fakeFormat,
    limit: limit,
  );

  group('nextEntries', () {
    test('merges launches and events in time order', () {
      final picked = pick(
        launches: [
          launch('a', const Duration(days: 2)),
          launch('b', const Duration(hours: 1)),
        ],
        events: [event(1, const Duration(hours: 5))],
      );

      expect(picked.map((e) => e.payload), [
        'launch-details::b',
        'event-details::1',
        'launch-details::a',
      ]);
    });

    test('drops what has already happened', () {
      // Launch listings start a day in the past, so this is the common case
      // rather than a hypothetical.
      final picked = pick(
        launches: [
          launch('past', const Duration(hours: -3)),
          launch('now', Duration.zero),
          launch('soon', const Duration(minutes: 1)),
        ],
      );

      expect(picked.map((e) => e.payload), ['launch-details::soon']);
    });

    test('stops at the most rows the widget can draw', () {
      final picked = pick(
        launches: List.generate(
          homeWidgetRows + 5,
          (i) => launch('l$i', Duration(hours: i + 1)),
        ),
      );

      expect(picked, hasLength(homeWidgetRows));
      expect(picked.first.payload, 'launch-details::l0');
    });

    test('an empty cache gives no rows rather than blank ones', () {
      expect(pick(), isEmpty);
    });

    test('skips anything it could not link to or date', () {
      final picked = pick(
        launches: [
          Launch(
            id: null,
            name: 'No id',
            net: now.add(const Duration(days: 1)),
          ),
          const Launch(id: 'x', name: 'No date'),
          launch('ok', const Duration(days: 1)),
        ],
      );

      expect(picked.map((e) => e.payload), ['launch-details::ok']);
    });

    test('the mission is the headline, the rocket goes below it', () {
      // The API's `name` is "Falcon 9 Block 5 | Starlink Group 15-23", and in a
      // column this narrow that ellipsized the mission — the half you are
      // actually looking for.
      final picked = pick(
        launches: [
          Launch(
            id: 'a',
            name: 'Falcon 9 Block 5 | Starlink Group 15-23',
            mission: const Mission(name: 'Starlink Group 15-23'),
            rocket: const Rocket(
              configuration: RocketConfiguration(fullName: 'Falcon 9 Block 5'),
            ),
            net: now.add(const Duration(hours: 1)),
            netPrecision: const DatePrecision(abbrev: 'MIN'),
          ),
        ],
      );

      expect(picked.single.title, 'Starlink Group 15-23');
      expect(picked.single.subtitle, 'Falcon 9 Block 5 · 13:00');
    });

    test('a launch with no mission keeps the combined name, undivided', () {
      final picked = pick(launches: [launch('a', const Duration(hours: 1))]);

      // Splitting the name here would put half of it in both lines.
      expect(picked.single.title, 'A launch');
      expect(picked.single.subtitle, '13:00');
    });

    test('an event has no rocket, so its subtitle is just the time', () {
      final picked = pick(events: [event(1, const Duration(hours: 2))]);

      expect(picked.single.title, 'An event');
      expect(picked.single.subtitle, '14:00');
    });

    test('the payload is the one the app already understands', () {
      // Same string a notification carries, so a tap reuses the existing deep
      // link rather than adding a second way in.
      final picked = pick(
        launches: [launch('abc', const Duration(hours: 1))],
        events: [event(7, const Duration(hours: 2))],
      );

      expect(picked[0].payload, 'launch-details::abc');
      expect(picked[1].payload, 'event-details::7');
    });
  });

  group('nextRefreshDelay', () {
    test('waits for midnight when nothing happens sooner', () {
      final entries = pick(launches: [launch('a', const Duration(days: 3))]);

      expect(nextRefreshDelay(entries, now), untilNextLocalMidnight(now));
    });

    test('waits for the first entry when it passes before midnight', () {
      final entries = pick(launches: [launch('a', const Duration(hours: 2))]);

      expect(
        nextRefreshDelay(entries, now),
        const Duration(hours: 2, minutes: 1),
      );
    });

    test('takes the sooner of the two, whichever it is', () {
      // 11pm: midnight is an hour away, the launch two.
      final late = DateTime(2026, 9, 12, 23, 0);
      final entries = [
        WidgetEntry(
          title: 'x',
          subtitle: 'x',
          payload: 'launch-details::x',
          at: late.add(const Duration(hours: 2)),
        ),
      ];

      expect(nextRefreshDelay(entries, late), untilNextLocalMidnight(late));
    });

    test('still waits for midnight when there is nothing to show', () {
      expect(nextRefreshDelay(const [], now), untilNextLocalMidnight(now));
    });

    test('never asks to be run in the past', () {
      for (var h = 0; h < 24; h++) {
        final at = DateTime(2026, 9, 12, h, 30);
        final entries = [
          WidgetEntry(
            title: 'x',
            subtitle: 'x',
            payload: 'p',
            at: at.add(const Duration(minutes: 5)),
          ),
        ];

        expect(nextRefreshDelay(entries, at), greaterThan(Duration.zero));
      }
    });
  });
}
