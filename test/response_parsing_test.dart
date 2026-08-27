import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rockit/apis/launch_library/api.dart';
import 'package:rockit/apis/launch_library/common.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/apis/spaceflightnews/api.dart';

/// Recorded 2.3.0 responses, so these never touch the rate-limited live API.
Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  group('UpcomingLaunchesResponse (2.3.0)', () {
    late UpcomingLaunchesResponse res;

    setUp(
      () => res = UpcomingLaunchesResponse.fromJson(fixture('v230_launches')),
    );

    test('parses a recorded response', () {
      expect(res.results, hasLength(5));
      expect(res.count, greaterThan(0));

      final launch = res.results.first;
      expect(launch.id, isNotEmpty);
      expect(launch.name, isNotEmpty);
      expect(launch.status?.name, isNotNull);
    });

    test('parses net as a real DateTime', () {
      // 2.2.0 handed these out as strings and every call site re-parsed them.
      for (final launch in res.results) {
        expect(launch.net, isA<DateTime>());
      }
    });

    test('carries the precision that drives the whole time display', () {
      final abbrevs = res.results.map((l) => l.netPrecision?.abbrev).toList();

      expect(abbrevs, containsAll(['SEC', 'MIN', 'DAY', 'M', 'Q3']));

      final kinds = res.results.map((l) => l.netPrecision?.kind).toSet();
      expect(kinds, contains(DatePrecisionKind.quarter));
      expect(kinds, contains(DatePrecisionKind.month));
    });

    test('parses the image object, not just a URL', () {
      final image = res.results
          .map((l) => l.image)
          .firstWhere((i) => i != null)!;

      expect(image.imageUrl, startsWith('http'));
      expect(image.thumbnailUrl, startsWith('http'));
    });

    test('parses booster reuse where the API provides it', () {
      final reused = res.results
          .expand((l) => l.rocket?.launcherStage ?? const <LauncherStage>[])
          .where((s) => s.reused == true)
          .toList();

      expect(reused, isNotEmpty, reason: 'fixture includes a reused booster');

      final stage = reused.first;
      expect(stage.launcher?.serialNumber, isNotEmpty);
      expect(stage.launcherFlightNumber, isNotNull);
    });

    test('parses durations into Duration, not strings', () {
      final turnarounds = res.results
          .map((l) => l.padTurnaround)
          .whereType<Duration>();

      expect(turnarounds, isNotEmpty);
      expect(turnarounds.every((d) => d > Duration.zero), isTrue);
    });

    test('parses the pad timezone used for local site time', () {
      final zones = res.results
          .map((l) => l.pad?.location?.timezoneName)
          .whereType<String>();

      expect(zones, isNotEmpty);
      expect(zones.first, contains('/'));
    });

    test('every launch has the id the listing dedupes on', () {
      final ids = res.results.map((l) => l.id).toSet();
      expect(ids, hasLength(res.results.length));
    });

    test('an empty result set parses to an empty list', () {
      final empty = UpcomingLaunchesResponse.fromJson({
        'count': 0,
        'next': null,
        'previous': null,
        'results': <dynamic>[],
      });

      expect(empty.results, isEmpty);
      expect(empty.next, isNull);
    });

    test('a response missing every optional key still parses', () {
      // Response modes drop keys wholesale; this must degrade, not throw.
      final sparse = UpcomingLaunchesResponse.fromJson({
        'results': [
          {'id': 'abc', 'name': 'Some rocket'},
        ],
      });

      final launch = sparse.results.single;
      expect(launch.id, 'abc');
      expect(launch.net, isNull);
      expect(launch.status, isNull);
      expect(launch.rocket, isNull);
      // Lists default to empty rather than null, so callers can just iterate.
      expect(launch.updates, isEmpty);
      expect(launch.vidUrls, isEmpty);
    });
  });

  group('UpcomingEventsResponse (2.3.0)', () {
    late UpcomingEventsResponse res;

    setUp(() => res = UpcomingEventsResponse.fromJson(fixture('v230_events')));

    test('parses a recorded response', () {
      expect(res.results, hasLength(5));

      final event = res.results.first;
      expect(event.id, isNotNull);
      expect(event.name, isNotEmpty);
    });

    test('events are never precise to a time', () {
      // Which is exactly why they must not get a ticking countdown.
      for (final event in res.results) {
        expect(event.datePrecision?.kind.hasUsableTime, isFalse);
      }
    });

    test('reads the renamed image field', () {
      final withImage = res.results.where((e) => e.image != null);

      expect(withImage, isNotEmpty);
      expect(withImage.first.image?.imageUrl, startsWith('http'));
    });

    test('every event has the id the listing dedupes on', () {
      final ids = res.results.map((e) => e.id).toSet();
      expect(ids, hasLength(res.results.length));
    });
  });

  group('backwards compatibility with cached 2.2.0 responses', () {
    test('accepts a bare image URL string', () {
      final launch = Launch.fromJson({
        'id': 'x',
        'image': 'https://example.invalid/rocket.jpg',
      });

      expect(launch.image?.imageUrl, 'https://example.invalid/rocket.jpg');
      expect(launch.image?.thumbnailUrl, isNull);
    });

    test('accepts the old infoURLs / vidURLs spellings', () {
      final launch = Launch.fromJson({
        'id': 'x',
        'vidURLs': [
          {'title': 'Livestream', 'url': 'https://example.invalid/live'},
        ],
      });

      expect(launch.vidUrls.single.title, 'Livestream');
    });

    test('accepts pad latitude as a string', () {
      // 2.2.0 sent these as strings; a plain cast would have thrown.
      final pad = Pad.fromJson({'latitude': '28.60822681'});

      expect(pad.latitude, closeTo(28.608, 0.001));
    });
  });

  group('ApiImage.urlFor', () {
    const image = ApiImage(
      imageUrl: 'https://example.invalid/full.jpg',
      thumbnailUrl: 'https://example.invalid/thumb.jpg',
    );

    test('uses the thumbnail only when the box is smaller than it', () {
      // Thumbnails really are 256x256, so anything bigger would upscale.
      expect(image.urlFor(64), image.thumbnailUrl);
      expect(image.urlFor(256), image.thumbnailUrl);
      expect(image.urlFor(257), image.imageUrl);
      expect(image.urlFor(1080), image.imageUrl);
    });

    test('falls back when one of the two is missing', () {
      const noThumb = ApiImage(imageUrl: 'https://example.invalid/full.jpg');
      expect(noThumb.urlFor(32), noThumb.imageUrl);

      const onlyThumb = ApiImage(thumbnailUrl: 'https://example.invalid/t.jpg');
      expect(onlyThumb.urlFor(4000), onlyThumb.thumbnailUrl);
    });
  });

  group('LaunchLibraryAPI.listingCutoff', () {
    test('rounds down to midnight UTC so the cache key is stable', () {
      // The cutoff goes in the query string, which is the HTTP cache key. If it
      // moved with the clock the cache would never hit.
      final morning = LaunchLibraryAPI.listingCutoff(
        DateTime.utc(2026, 8, 27, 8, 40, 12),
      );
      final evening = LaunchLibraryAPI.listingCutoff(
        DateTime.utc(2026, 8, 27, 23, 59, 59),
      );

      expect(morning, evening);
      expect(morning, DateTime.utc(2026, 8, 26));
    });

    test('keeps a day of the recent past', () {
      final cutoff = LaunchLibraryAPI.listingCutoff(
        DateTime.utc(2026, 8, 27, 12),
      );

      expect(cutoff.isBefore(DateTime.utc(2026, 8, 27)), isTrue);
    });

    test('normalises a local time to UTC', () {
      final cutoff = LaunchLibraryAPI.listingCutoff(
        DateTime.utc(2026, 1, 1, 3).toLocal(),
      );

      expect(cutoff.isUtc, isTrue);
    });
  });

  group('SpaceFlightNewsAPI.parseArticles', () {
    test('parses a recorded response', () {
      final articles = SpaceFlightNewsAPI.parseArticles(fixture('articles'));

      expect(articles, hasLength(2));
      expect(articles.first.title, isNotEmpty);
      expect(articles.first.publishedAt, isA<DateTime>());
    });

    test('an empty result set parses to an empty list', () {
      expect(
        SpaceFlightNewsAPI.parseArticles({'count': 0, 'results': <dynamic>[]}),
        isEmpty,
      );
    });
  });
}
