import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rockit/apis/cache_first.dart';
import 'package:rockit/apis/error_details.dart';

/// A loader whose completion the test controls, so the in-flight state is
/// observable instead of being a race.
class _Gate<T> {
  final completer = Completer<T>();
  int calls = 0;

  Future<T> call() {
    calls++;
    return completer.future;
  }
}

void main() {
  group('CacheFirstController', () {
    test('shows cached data before the refresh finishes', () async {
      final fresh = _Gate<String>();

      final controller = CacheFirstController<String>(
        loadCached: () async => 'cached',
        loadFresh: fresh.call,
      );

      final started = controller.start();

      // Let the cache read (a microtask) settle without completing the refresh.
      await Future<void>.delayed(Duration.zero);

      expect(controller.data, 'cached');
      expect(controller.showingCached, isTrue);
      expect(controller.status, ListingStatus.refreshing);

      fresh.completer.complete('fresh');
      await started;

      expect(controller.data, 'fresh');
      expect(controller.showingCached, isFalse);
      expect(controller.status, ListingStatus.ready);
    });

    test('refreshes even when the cache hit, to keep data current', () async {
      final fresh = _Gate<String>();

      final controller = CacheFirstController<String>(
        loadCached: () async => 'cached',
        loadFresh: fresh.call,
      );

      final started = controller.start();
      await Future<void>.delayed(Duration.zero);

      fresh.completer.complete('fresh');
      await started;

      expect(fresh.calls, 1);
    });

    test('with no cache it loads, showing nothing until the network answers',
        () async {
      final fresh = _Gate<String>();

      final controller = CacheFirstController<String>(
        loadCached: () async => null,
        loadFresh: fresh.call,
      );

      final started = controller.start();
      await Future<void>.delayed(Duration.zero);

      expect(controller.data, isNull);
      expect(controller.status, ListingStatus.loading);

      fresh.completer.complete('fresh');
      await started;

      expect(controller.data, 'fresh');
      expect(controller.status, ListingStatus.ready);
    });

    test('a failed refresh keeps the cached data on screen', () async {
      final controller = CacheFirstController<String>(
        loadCached: () async => 'cached',
        loadFresh: () async => throw Exception('rate limited'),
      );

      await controller.start();

      expect(controller.data, 'cached');
      expect(controller.status, ListingStatus.ready);
      expect(controller.fatalError, isNull);
      // The user is told once that this is not the latest data.
      expect(controller.takeNotice(), ErrorType.cachedFallback);
      expect(controller.takeNotice(), isNull);
    });

    test('a failed load with nothing cached is fatal', () async {
      final controller = CacheFirstController<String>(
        loadCached: () async => null,
        loadFresh: () async => throw Exception('offline'),
      );

      await controller.start();

      expect(controller.data, isNull);
      expect(controller.status, ListingStatus.failed);
      expect(controller.fatalError, isNotNull);
    });

    test('a retry after a fatal failure recovers', () async {
      var attempt = 0;

      final controller = CacheFirstController<String>(
        loadCached: () async => null,
        loadFresh: () async {
          if (attempt++ == 0) {
            throw Exception('offline');
          }
          return 'fresh';
        },
      );

      await controller.start();
      expect(controller.status, ListingStatus.failed);

      await controller.refresh();

      expect(controller.data, 'fresh');
      expect(controller.status, ListingStatus.ready);
      expect(controller.fatalError, isNull);
    });

    test('a cache read that throws still refreshes', () async {
      final controller = CacheFirstController<String>(
        loadCached: () async => throw Exception('corrupt cache'),
        loadFresh: () async => 'fresh',
      );

      await controller.start();

      expect(controller.data, 'fresh');
      expect(controller.status, ListingStatus.ready);
    });

    test('a slow load landing after a newer one is discarded', () async {
      final slow = _Gate<String>();
      var useSlow = true;

      final controller = CacheFirstController<String>(
        loadCached: () async => null,
        loadFresh: () {
          if (useSlow) {
            return slow.call();
          }
          return Future.value('second');
        },
      );

      final first = controller.start();
      await Future<void>.delayed(Duration.zero);

      // A pull-to-refresh supersedes the in-flight first load.
      useSlow = false;
      await controller.refresh();
      expect(controller.data, 'second');

      // The original request finally answers with older data; it must not win.
      slow.completer.complete('first');
      await first;

      expect(controller.data, 'second');
    });

    test('notices from a partially successful load surface once', () async {
      final controller = CacheFirstController<String>(
        loadCached: () async => null,
        loadFresh: () async => 'fresh',
      );

      controller.noteNotice(ErrorType.incompleteData);

      expect(controller.takeNotice(), ErrorType.incompleteData);
      expect(controller.takeNotice(), isNull);
    });

    test('does not notify after dispose', () async {
      final fresh = _Gate<String>();
      var notifications = 0;

      final controller = CacheFirstController<String>(
        loadCached: () async => null,
        loadFresh: fresh.call,
      );
      controller.addListener(() => notifications++);

      final started = controller.start();
      await Future<void>.delayed(Duration.zero);

      final before = notifications;
      controller.dispose();

      fresh.completer.complete('fresh');
      await started;

      expect(notifications, before);
    });
  });
}
