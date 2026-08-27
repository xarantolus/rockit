import 'package:flutter_test/flutter_test.dart';
import 'package:rockit/apis/launch_library/api.dart';
import 'package:rockit/apis/spaceflightnews/api.dart';
import 'package:rockit/background/handler.dart';

/// The background cache warmer is only worth anything if it fills the exact
/// entries the UI reads back, and the URL is the cache key. A stray parameter
/// on either side turns the whole thing into a silent no-op: the fetch still
/// succeeds, the listing still opens on a spinner, and nothing reports an
/// error. These are the checks that would catch that.
void main() {
  group('the warmed URLs are the ones the UI reads', () {
    final api = LaunchLibraryAPI();

    test('launches', () {
      expect(
        api.upcomingLaunchesUri().toString(),
        api.upcomingLaunchesUri(next: null).toString(),
      );
    });

    test('the listing cutoff is stable across a day', () {
      // Not rounding would mint a new URL on every call, so the warmer would
      // fill an entry nothing ever reads.
      final morning = DateTime.utc(2026, 8, 27, 6, 15);
      final evening = DateTime.utc(2026, 8, 27, 23, 45);

      expect(
        api.upcomingLaunchesUri(now: morning).toString(),
        api.upcomingLaunchesUri(now: evening).toString(),
      );
      expect(
        api.upcomingEventsUri(now: morning).toString(),
        api.upcomingEventsUri(now: evening).toString(),
      );
    });

    test('and moves on to the next one', () {
      final today = DateTime.utc(2026, 8, 27, 12);
      final tomorrow = DateTime.utc(2026, 8, 28, 12);

      expect(
        api.upcomingLaunchesUri(now: today).toString(),
        isNot(api.upcomingLaunchesUri(now: tomorrow).toString()),
      );
    });

    test('news', () {
      expect(
        SpaceFlightNewsAPI().articlesUri().toString(),
        contains('limit=${SpaceFlightNewsAPI.pageSize}'),
      );
    });

    test('the listing asks for detailed launches', () {
      // Which is what lets a subscribed launch found in the warmed listing be
      // processed without a second request: mode=list would carry no updates.
      expect(api.upcomingLaunchesUri().queryParameters['mode'], 'detailed');
      expect(api.upcomingEventsUri().queryParameters['mode'], 'detailed');
    });
  });

  group('cache warm schedule', () {
    test('runs twice a day', () {
      // Two Launch Library requests a run, against fifteen an hour.
      expect(BackgroundHandler.cacheWarmInterval, const Duration(hours: 12));
    });

    test('has its own task name, so the callback can route it', () {
      expect(
        BackgroundHandler.periodicCacheWarmTaskName,
        isNot(BackgroundHandler.periodicLaunchUpdateTaskName),
      );
      expect(
        BackgroundHandler.periodicCacheWarmTaskName,
        isNot(BackgroundHandler.periodicEventUpdateTaskName),
      );
    });
  });
}
