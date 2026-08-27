import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/apis/spaceflightnews/api.dart';

/// Recorded responses, so these never touch the rate-limited live API.
dynamic fixture(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync());

void main() {
  group('UpcomingLaunchesResponse', () {
    test('parses a recorded response', () {
      final res = UpcomingLaunchesResponse.fromJson(fixture('launches'));

      expect(res.results, hasLength(2));
      expect(res.next, isNotNull);
      expect(res.count, greaterThan(0));

      final launch = res.results!.first;
      expect(launch.id, isNotEmpty);
      expect(launch.name, isNotEmpty);
      expect(launch.status?.name, isNotNull);
    });

    test('every launch has the id the listing dedupes on', () {
      final res = UpcomingLaunchesResponse.fromJson(fixture('launches'));

      final ids = res.results!.map((l) => l.id).toSet();
      expect(ids, hasLength(res.results!.length));
    });

    test('parses the nested rocket and pad detail the cards render', () {
      final launch =
          UpcomingLaunchesResponse.fromJson(fixture('launches')).results!.first;

      expect(launch.rocket?.configuration?.fullName, isNotNull);
      expect(launch.pad?.name, isNotNull);
    });

    test('an empty result set parses to an empty list', () {
      final res = UpcomingLaunchesResponse.fromJson({
        'count': 0,
        'next': null,
        'previous': null,
        'results': <dynamic>[],
      });

      expect(res.results, isEmpty);
      expect(res.next, isNull);
    });
  });

  group('model constructors', () {
    // These used to take their named parameters and silently drop them, so
    // building a response by hand produced an object with every field null.
    test('UpcomingLaunchesResponse keeps what it is given', () {
      final res = UpcomingLaunchesResponse(
        count: 3,
        next: 'https://example.invalid/next',
        previous: null,
        results: const <Launch>[],
      );

      expect(res.count, 3);
      expect(res.next, 'https://example.invalid/next');
      expect(res.results, isEmpty);
    });

    test('Launch keeps what it is given', () {
      final launch = Launch(id: 'abc', name: 'Falcon 9');

      expect(launch.id, 'abc');
      expect(launch.name, 'Falcon 9');
      expect(launch.status, isNull);
    });
  });

  group('UpcomingEventsResponse', () {
    test('parses a recorded response', () {
      final res = UpcomingEventsResponse.fromJson(fixture('events'));

      expect(res.results, hasLength(2));

      final event = res.results!.first;
      expect(event.id, isNotNull);
      expect(event.name, isNotEmpty);
    });

    test('every event has the id the listing dedupes on', () {
      final res = UpcomingEventsResponse.fromJson(fixture('events'));

      final ids = res.results!.map((e) => e.id).toSet();
      expect(ids, hasLength(res.results!.length));
    });
  });

  group('SpaceFlightNewsAPI.parseArticles', () {
    test('parses a recorded response', () {
      final articles = SpaceFlightNewsAPI.parseArticles(fixture('articles'));

      expect(articles, hasLength(2));

      final article = articles.first;
      expect(article.id, isNonZero);
      expect(article.title, isNotEmpty);
      expect(article.url, isNotNull);
      expect(article.publishedAt, isA<DateTime>());
    });

    test('an empty result set parses to an empty list', () {
      final articles = SpaceFlightNewsAPI.parseArticles({
        'count': 0,
        'results': <dynamic>[],
      });

      expect(articles, isEmpty);
    });
  });
}
