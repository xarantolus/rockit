import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rockit/apis/coalesce.dart';
import 'package:rockit/apis/spaceflightnews/api.dart';

void main() {
  group('coalesce', () {
    test(
      'a second caller joins the running request instead of starting one',
      () async {
        final inFlight = <String, Future<int>>{};
        final completer = Completer<int>();
        var starts = 0;

        Future<int> start() {
          starts++;
          return completer.future;
        }

        final first = coalesce(inFlight, 'a', start);
        final second = coalesce(inFlight, 'a', start);

        completer.complete(7);

        expect(await first, 7);
        expect(await second, 7);
        expect(starts, 1);
      },
    );

    test('different keys do not share', () async {
      final inFlight = <String, Future<int>>{};
      var starts = 0;

      Future<int> start(int value) {
        starts++;
        return Future.value(value);
      }

      expect(await coalesce(inFlight, 'a', () => start(1)), 1);
      expect(await coalesce(inFlight, 'b', () => start(2)), 2);
      expect(starts, 2);
    });

    test(
      'the entry is gone once the request settles, so the next call runs',
      () async {
        final inFlight = <String, Future<int>>{};
        var starts = 0;

        Future<int> start() {
          starts++;
          return Future.value(1);
        }

        await coalesce(inFlight, 'a', start);
        expect(inFlight, isEmpty);

        await coalesce(inFlight, 'a', start);
        expect(starts, 2);
      },
    );

    test('a failure is not remembered as the answer', () async {
      final inFlight = <String, Future<int>>{};

      await expectLater(
        coalesce(inFlight, 'a', () => Future<int>.error(StateError('nope'))),
        throwsStateError,
      );

      expect(inFlight, isEmpty);
      expect(await coalesce(inFlight, 'a', () => Future.value(1)), 1);
    });

    test('joined callers see the same failure', () async {
      final inFlight = <String, Future<int>>{};
      final completer = Completer<int>();

      final first = coalesce(inFlight, 'a', () => completer.future);
      final second = coalesce(inFlight, 'a', () => Future.value(0));

      completer.completeError(StateError('nope'));

      await expectLater(first, throwsStateError);
      await expectLater(second, throwsStateError);
    });
  });

  group('article paging', () {
    test('every page asks for the full page size', () {
      expect(
        SpaceFlightNewsAPI().articlesUri().queryParameters['limit'],
        '${SpaceFlightNewsAPI.pageSize}',
      );
    });

    test('the first page has no offset, so it is one stable cache key', () {
      expect(
        SpaceFlightNewsAPI().articlesUri().queryParameters,
        isNot(contains('offset')),
      );
    });

    test('later pages carry the offset and keep the limit', () {
      final uri = SpaceFlightNewsAPI().articlesUri(SpaceFlightNewsAPI.pageSize);

      expect(uri.queryParameters['offset'], '${SpaceFlightNewsAPI.pageSize}');
      expect(uri.queryParameters['limit'], '${SpaceFlightNewsAPI.pageSize}');
    });

    test('the prefetch and the tab agree on a URL, so they can be joined', () {
      // The prefetch only helps if it fills the exact cache entry the listing
      // reads back; the URL is the cache key.
      expect(
        SpaceFlightNewsAPI().articlesUri().toString(),
        SpaceFlightNewsAPI().articlesUri(null).toString(),
      );
    });
  });
}
