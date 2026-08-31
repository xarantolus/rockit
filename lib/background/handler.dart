import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rockit/apis/cache_janitor.dart';
import 'package:rockit/apis/launch_library/api.dart';
import 'package:rockit/background/imminent_check.dart';
import 'package:rockit/background/reminders.dart';
import 'package:rockit/background/keywords.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/apis/spaceflightnews/api.dart';
import 'package:rockit/notifications/create.dart';
import 'package:rockit/time/precision_time.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

// This function will be called by Android when a task should be run
@pragma('vm:entry-point')
void backgroundTaskCallback() {
  // Overwrite debug print logic
  final oldDebugPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    oldDebugPrint(
      "xarantolus${kDebugMode ? '.debug' : ''}.rockit: ${message ?? "No message"}",
      wrapWidth: wrapWidth,
    );
  };

  Workmanager().executeTask((task, inputData) async {
    var handler = BackgroundHandler.withNotifications(
      await NotificationHandler.create(),
    );

    return await handler.callback(task, inputData);
  });
}

class BackgroundHandler {
  static const actionLaunchDetails = "launch-details";
  static const actionEventDetails = "event-details";

  /// Separate actions for the "this changed" notifications, so tapping one can
  /// land on the update that prompted it rather than the top of the page.
  static const actionLaunchUpdate = "launch-update";
  static const actionEventUpdate = "event-update";

  static BackgroundHandler? instance;

  FlutterLocalNotificationsPlugin? notifications;

  factory BackgroundHandler.withNotifications(
    FlutterLocalNotificationsPlugin notifs,
  ) {
    instance ??= BackgroundHandler._internal(notifs);

    return instance!;
  }

  factory BackgroundHandler() {
    if (instance == null) {
      throw Exception("BackgroundHandler() initialized when instance was null");
    }
    if (instance!.notifications == null) {
      throw Exception(
        "BackgroundHandler() initialized when instance notification plugin was null",
      );
    }
    return instance!;
  }

  BackgroundHandler._internal(this.notifications) {
    tz.initializeTimeZones();
  }

  static const periodicLaunchUpdateTaskName = "update:launch:periodic";
  static const periodicEventUpdateTaskName = "update:event:periodic";

  /// Refreshes the first page of every listing on a schedule, so opening the
  /// app paints real data instead of a spinner. Only one of these ever exists,
  /// hence a fixed id rather than one per subscription.
  /// Refreshes every subscription in one request rather than one apiece.
  ///
  /// There used to be a periodic task per subscribed launch, each fetching
  /// that one launch every hour: N subscriptions cost N requests an hour
  /// against a budget of fifteen, so fifteen subscriptions throttled the app
  /// permanently. Batching by id makes it two requests a run whatever the
  /// number — one for launches, one for events.
  static const periodicSubscriptionRefreshTaskName = "subs:refresh:periodic";
  static const _subscriptionRefreshTaskId = "subs-refresh";

  /// How often that runs. Hourly is fine for a launch days away; one closer
  /// than [_imminentWindow] gets its own one-off check instead.
  static const subscriptionRefreshInterval = Duration(hours: 1);

  static const periodicCacheWarmTaskName = "cache:warm:periodic";
  static const _cacheWarmTaskId = "cache-warm";

  /// Reading *further* into the listings than the first page. Split from the
  /// warm above because it wants a different constraint: this is bulk data
  /// nobody asked for, so it waits for an unmetered connection, which is the
  /// usual treatment for background prefetch of any size.
  static const periodicCacheDeepenTaskName = "cache:deepen:periodic";
  static const _cacheDeepenTaskId = "cache-deepen";

  /// Twice a day. The cost is two Launch Library requests per run against a
  /// budget of fifteen an hour, and its data barely moves faster than that;
  /// news is free but there is no reason to fetch it on its own schedule.
  static const cacheWarmInterval = Duration(hours: 12);

  final _periodicTaskConstraints = Constraints(
    networkType: NetworkType.connected,
  );

  NotificationDetails _getLaunchNotifDetails(String tag) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'Rocket Launch Notifications',
        'Rocket Launch Notifications',
        channelDescription:
            'Notifications for rocket launches, e.g. when a launch is about to happen.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        tag: tag,
      ),
    );
  }

  NotificationDetails _getLaunchUpdateNotifDetails(String tag) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'Rocket Launch Updates',
        'Rocket Launch Updates',
        channelDescription:
            'Notifications when rocket launches are updated, e.g. when a launch is delayed for some reason.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        tag: tag,
      ),
    );
  }

  // Return true for successful tasks, false for failed tasks that need to be retried
  // and Future.error() for tasks that failed and don't need to be retried
  Future<bool> callback(String task, Map<String, dynamic>? inputData) async {
    try {
      switch (task) {
        case periodicLaunchUpdateTaskName:
          return await handleLaunchUpdatePeriodic(inputData);
        case periodicEventUpdateTaskName:
          return await handleEventUpdatePeriodic(inputData);
        case periodicSubscriptionRefreshTaskName:
          return await handleSubscriptionRefresh();
        case periodicCacheWarmTaskName:
          return await handleCacheWarm();
        case periodicCacheDeepenTaskName:
          return await handleCacheDeepen();
        default:
          throw FormatException(
            "Expected task name to be for event or update, but got \"$task\"",
          );
      }
    } catch (err) {
      debugPrint("Error in scheduled task: $err");
      rethrow;
    }
  }

  /// Registers the cache warmer. Safe to call on every start.
  ///
  /// `update` rather than `replace`: replacing cancels the pending work and
  /// restarts the twelve hours, so on an app that is opened daily the task
  /// would never actually come due.
  Future<void> scheduleCacheWarming() async {
    try {
      await Workmanager().registerPeriodicTask(
        _cacheWarmTaskId,
        periodicCacheWarmTaskName,
        frequency: cacheWarmInterval,
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        constraints: _periodicTaskConstraints,
      );

      await Workmanager().registerPeriodicTask(
        _cacheDeepenTaskId,
        periodicCacheDeepenTaskName,
        frequency: cacheWarmInterval,
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        constraints: Constraints(networkType: NetworkType.unmetered),
      );

      // Registered unconditionally, like the warmers. With nothing subscribed
      // it reads two preference keys and returns, which is cheaper than
      // registering and cancelling it as subscriptions come and go.
      await Workmanager().registerPeriodicTask(
        _subscriptionRefreshTaskId,
        periodicSubscriptionRefreshTaskName,
        frequency: subscriptionRefreshInterval,
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        constraints: _periodicTaskConstraints,
      );

      await _retirePerItemTasks();
    } catch (err) {
      debugPrint("Could not schedule cache warming: $err");
    }
  }

  /// Cancels the per-subscription periodic tasks an older build registered.
  ///
  /// Once, behind a flag. **By name only** — never `cancelAll`, which would
  /// take the cache warmers with it. Anything the lists no longer mention was
  /// already cancelled by `unsubscribeFrom*`.
  Future<void> _retirePerItemTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    if (prefs.getBool(_retiredPerItemTasksKey) ?? false) {
      return;
    }

    try {
      for (final id in await _loadIDs(launchesKey)) {
        await Workmanager().cancelByUniqueName(_taskNameForLaunch(id));
      }

      for (final id in await _loadIDs(eventsKey)) {
        await Workmanager().cancelByUniqueName(_taskNameForEvent(id));
      }

      await prefs.setBool(_retiredPerItemTasksKey, true);
      debugPrint("Retired the per-subscription periodic tasks");
    } catch (err) {
      debugPrint("Could not retire the per-subscription tasks: $err");
    }
  }

  static const _retiredPerItemTasksKey = "retired-per-item-tasks";

  /// Refreshes every subscription in two requests: one listing filtered to the
  /// subscribed launch ids, one to the event ids.
  ///
  /// Returning false asks WorkManager to run the whole thing again, so it is
  /// only for "nothing worked at all".
  Future<bool> handleSubscriptionRefresh() async {
    final launchIDs = await _loadIDs(launchesKey);
    final eventIDs = await _loadIDs(eventsKey);

    if (launchIDs.isEmpty && eventIDs.isEmpty) {
      return true;
    }

    if (await _spendableRequests() <= 0) {
      return true;
    }

    final api = LaunchLibraryAPI();
    var worked = false;

    try {
      final launches = await api.launchesByIds(launchIDs);
      worked = true;

      for (final launch in launches) {
        final id = launch.id;
        if (id == null) {
          continue;
        }

        try {
          await processLaunch(launch, id);
        } catch (err) {
          debugPrint("Could not process subscribed launch $id: $err");
        }
      }

      await _scheduleImminentChecks(launches);
    } catch (err) {
      debugPrint("Could not refresh subscribed launches: $err");
    }

    try {
      final parsed = eventIDs
          .map(int.tryParse)
          .whereType<int>()
          .toList(growable: false);

      if (parsed.isNotEmpty) {
        final events = await api.eventsByIds(parsed);
        worked = true;

        for (final event in events) {
          final id = event.id;
          if (id == null) {
            continue;
          }

          try {
            await processEvent(event, "$id");
          } catch (err) {
            debugPrint("Could not process subscribed event $id: $err");
          }
        }
      }
    } catch (err) {
      debugPrint("Could not refresh subscribed events: $err");
    }

    await _letTheCacheIndexSettle();

    return worked;
  }

  /// An hour is too coarse for a launch about to fly, but a quarter-hourly
  /// periodic task for every subscription is worse than the problem. A launch
  /// inside [imminentWindow] instead gets a one-off check a minute before each
  /// reminder, so a slip cancels or moves that reminder *before* it goes out
  /// rather than after: without it a launch that has slipped an hour still
  /// announces "5 minutes", and the correction arrives too late to matter.
  Future<void> _scheduleImminentChecks(List<Launch> launches) async {
    final now = DateTime.now();

    for (final launch in launches) {
      final id = launch.id;
      if (id == null) {
        continue;
      }

      for (final check in imminentCheckDelays(launch.net, now)) {
        try {
          await Workmanager().registerOneOffTask(
            imminentCheckTaskName(id, check.offset),
            periodicLaunchUpdateTaskName,
            initialDelay: check.delay,
            inputData: {"launchId": id},
            existingWorkPolicy: ExistingWorkPolicy.replace,
            constraints: _periodicTaskConstraints,
          );
        } catch (err) {
          debugPrint("Could not schedule a near-liftoff check for $id: $err");
        }
      }
    }
  }

  /// Fetches the first page of launches, events and news purely for the cache.
  ///
  /// This runs in a background isolate, but it is the same app: the HTTP cache
  /// is one directory on disk, so what this stores is what the UI reads back.
  /// (If the app happens to be in the foreground at the same time, the two
  /// isolates can overwrite each other's cache *index*; the response files
  /// survive, so the worst case is a cache miss, not bad data.)
  /// The essential refresh: the first page of each listing, plus news.
  Future<bool> handleCacheWarm() async {
    final api = LaunchLibraryAPI();

    var allowance = await _spendableRequests();
    if (allowance <= 0) {
      return true;
    }

    final results = await Future.wait([
      if (allowance-- > 0)
        _warmCache("launches", () async {
          final resp = await api.upcomingLaunches();
          await _refreshSubscriptionsFrom(launches: resp.data.results);
        }),
      if (allowance-- > 0)
        _warmCache("events", () async {
          final resp = await api.upcomingEvents();
          await _refreshSubscriptionsFrom(events: resp.data.results);
        }),
      // News is a different API with no budget to protect.
      _warmCache("news", () => SpaceFlightNewsAPI().articles()),
    ]);

    await _letTheCacheIndexSettle();

    // After the writes, so what this run just stored counts towards the budget
    // rather than being swept on the next one.
    await CacheJanitor().sweep();

    // Returning false asks WorkManager to run the whole task again, which is
    // only right when nothing worked at all.
    return results.any((ok) => ok);
  }

  /// Reads further into both listings with whatever budget is spare.
  ///
  /// Deepens the search corpus, and files more launches under their own URLs
  /// for everything that looks one up by id — an event's attached launch, a
  /// notification tap, the subscriptions page.
  Future<bool> handleCacheDeepen() async {
    final api = LaunchLibraryAPI();

    var allowance = await _spendableRequests();
    if (allowance <= 0) {
      return true;
    }

    String? launchNext;
    String? eventNext;
    var pages = 0;

    try {
      // Sequential: each page's `next` only exists once the one before it has
      // come back. Launches first, since there are far more of them.
      // Scanned as well as cached: a keyword's match is often further down
      // the listing than the first page, and these pages are already paid for.
      final first = (await api.upcomingLaunches()).data;
      await scanForKeywordMatches(first.results);
      launchNext = first.next;
      allowance--;

      while (allowance-- > 0 && launchNext != null) {
        final page = (await api.upcomingLaunches(next: launchNext)).data;
        await scanForKeywordMatches(page.results);
        launchNext = page.next;
        pages++;
      }

      if (allowance > 0) {
        eventNext = (await api.upcomingEvents()).data.next;
        while (allowance-- > 0 && eventNext != null) {
          eventNext = (await api.upcomingEvents(next: eventNext)).data.next;
          pages++;
        }
      }
    } catch (err) {
      debugPrint("Could not read further into the listings: $err");
    }

    debugPrint("Read $pages extra listing page(s)");
    await _letTheCacheIndexSettle();

    return true;
  }

  /// How many Launch Library requests this job may spend.
  ///
  /// Asking is free — `/api-throttle/` does not count against the budget — and
  /// stopping at half of it leaves room for whatever the user does next.
  Future<int> _spendableRequests() async {
    final throttle = await LaunchLibraryAPI().throttle();
    final allowance = throttle?.requestsUntilHalfSpent ?? _blindAllowance;

    if (allowance <= 0) {
      debugPrint("Half the request budget is already spent; not fetching");
    }

    return allowance;
  }

  /// `flutter_cache_manager` writes its index three seconds after the last
  /// put, so a job that returns immediately loses everything it just stored:
  /// the response files are on disk and nothing can find them. Waiting is the
  /// difference between the extra pages being cached and being thrown away.
  Future<void> _letTheCacheIndexSettle() {
    return Future.delayed(const Duration(seconds: 5));
  }

  /// What to spend when the budget cannot be read: the two first pages, which
  /// is what the job did before it asked at all.
  static const _blindAllowance = 2;

  /// Runs the subscription logic over anything we already downloaded.
  ///
  /// The listing is `mode=detailed`, so a subscribed launch that appears in it
  /// carries exactly what the per-launch task would have fetched — updates
  /// included. Processing it here means the hourly per-launch tasks find
  /// nothing new to report and, more importantly, that a subscription stays
  /// current even on a device where those tasks are being throttled.
  ///
  /// Anything *not* in the listing (further out than one page, or already
  /// past) is left to its own task; this never adds a request.
  Future<void> _refreshSubscriptionsFrom({
    List<Launch>? launches,
    List<Event>? events,
  }) async {
    if (launches != null) {
      // Before the refresh below, so anything a keyword has just picked up is
      // treated like every other subscription from here on.
      try {
        await scanForKeywordMatches(launches);
      } catch (err) {
        debugPrint("Could not scan the listing for keyword matches: $err");
      }

      final subscribed = (await _loadIDs(launchesKey)).toSet();

      for (final launch in launches) {
        final id = launch.id;
        if (id == null || !subscribed.contains(id)) {
          continue;
        }

        try {
          await processLaunch(launch, id);
          debugPrint("Refreshed subscribed launch $id from the listing");
        } catch (err) {
          debugPrint("Could not refresh subscribed launch $id: $err");
        }
      }
    }

    if (events != null) {
      final subscribed = (await _loadIDs(eventsKey)).toSet();

      for (final event in events) {
        final id = event.id;
        if (id == null || !subscribed.contains("$id")) {
          continue;
        }

        try {
          await processEvent(event, "$id");
          debugPrint("Refreshed subscribed event $id from the listing");
        } catch (err) {
          debugPrint("Could not refresh subscribed event $id: $err");
        }
      }
    }
  }

  Future<bool> _warmCache(String what, Future<void> Function() fetch) async {
    try {
      await fetch();
      debugPrint("Warmed the $what cache");

      return true;
    } catch (err) {
      debugPrint("Could not warm the $what cache: $err");

      return false;
    }
  }

  Future<DateTime?> _loadDate(String key) async {
    try {
      var instance = await SharedPreferences.getInstance();
      await instance.reload();

      return DateTime.tryParse(instance.getString(key)!);
    } catch (err) {
      debugPrint("Error loading date: $err");
    }
    return null;
  }

  Future<void> _saveDate(String key, DateTime date) async {
    try {
      var instance = await SharedPreferences.getInstance();
      await instance.reload();

      await instance.setString(key, date.toIso8601String());
    } catch (err) {
      debugPrint("Error in scheduled task: $err");
    }
  }

  Future<void> _deleteKey(String key) async {
    var instance = await SharedPreferences.getInstance();
    await instance.reload();
    await instance.remove(key);
  }

  Future<List<String>> _loadIDs(String key) async {
    try {
      var instance = await SharedPreferences.getInstance();
      await instance.reload();
      return instance.getStringList(key) ?? [];
    } catch (err) {
      debugPrint("Error loading IDs ($key): $err");
    }
    return [];
  }

  Future<String?> _loadString(String key) async {
    try {
      final instance = await SharedPreferences.getInstance();
      await instance.reload();

      return instance.getString(key);
    } catch (err) {
      debugPrint("Error loading $key: $err");

      return null;
    }
  }

  Future<void> _saveString(String key, String value) async {
    try {
      final instance = await SharedPreferences.getInstance();
      await instance.reload();

      await instance.setString(key, value);
    } catch (err) {
      debugPrint("Error saving $key: $err");
    }
  }

  /// Not the old `precision:` key. That held a precision abbrev, so reusing it
  /// would read one as a display key on the first run after an update and
  /// announce a change that had not happened.
  String _getDisplayedTimeKey(String type, String id) =>
      "displaytime:$type:$id";

  /// Notifies when the time a subscriber can see actually changes.
  ///
  /// Only entries in the API's update feed produce a notification otherwise,
  /// and the changes that matter most are often not in it: a launch going from
  /// "NET October" to a real time, or slipping from Tuesday to Thursday.
  ///
  /// The test is [displayedTimeKey], not the raw [at]. A launch known only to
  /// the month moves within that month constantly and shows the same "NET
  /// October" throughout, so comparing instants would be pure noise; comparing
  /// what is rendered fires exactly when the screen would look different.
  Future<void> _notifyIfDisplayedTimeChanged({
    required String type,
    required String id,
    required String title,
    required DatePrecision? precision,
    required DateTime? at,
    required NotificationDetails details,
    required String payload,
  }) async {
    final key = _getDisplayedTimeKey(type, id);
    final previous = await _loadString(key);
    final current = displayedTimeKey(at, precision);

    await _saveString(key, current ?? "");

    // Nothing to compare against on the first run, which is the moment the
    // user subscribed. An empty current means the API has no date at all.
    if (previous == null || current == null || at == null) {
      return;
    }

    if (previous == current) {
      return;
    }

    // A date appearing for the first time is not a change of plan, and the
    // reminders only start meaning anything here.
    final wasUnknown = previous.isEmpty;
    final noun = type == "event" ? "event" : "launch";

    try {
      await notifications!.show(
        id: "time:$id".hashCode.abs(),
        title: title,
        body: wasUnknown
            ? "A $noun time has been set: ${_describeTime(at, precision)}"
            : "The $noun time changed to ${_describeTime(at, precision)}",
        notificationDetails: details,
        payload: payload,
      );
    } catch (err) {
      debugPrint("Could not notify about the new time for $id: $err");
    }
  }

  /// Says the time only as precisely as the API claims to know it, so a launch
  /// known to the month is not announced as a specific minute.
  static String _describeTime(DateTime at, DatePrecision? precision) {
    final local = at.toLocal();

    return switch (precision?.kind) {
      DatePrecisionKind.second ||
      DatePrecisionKind.minute ||
      DatePrecisionKind.hour ||
      null => DateFormat("EEE, d MMM y, HH:mm").format(local),
      DatePrecisionKind.day ||
      DatePrecisionKind.week ||
      DatePrecisionKind.unknown => DateFormat("EEE, d MMM y").format(local),
      DatePrecisionKind.month => DateFormat("MMMM y").format(local),
      DatePrecisionKind.quarter => "Q${quarterOf(local)} ${local.year}",
      DatePrecisionKind.year => "${local.year}",
      DatePrecisionKind.decade => "${local.year - local.year % 10}s",
    };
  }

  String _getUpdateKey(String type, String id) {
    return "update:$type:lastupdate:$id";
  }

  Future<bool> handleLaunchUpdatePeriodic(
    Map<String, dynamic>? inputData,
  ) async {
    // At first, we load the associated launch
    final launchId = inputData!["launchId"]!;

    // If this task was run even though it should not have been, we cancel it
    var markedLaunches = await _loadIDs(launchesKey);
    if (!markedLaunches.contains(launchId)) {
      await unsubscribeFromLaunch(launchId);
      return true;
    }

    return await processLaunch(
      (await LaunchLibraryAPI().launch(launchId)).data,
      launchId,
    );
  }

  /// Everything the periodic launch task does once it *has* the launch:
  /// notify about new updates, reschedule the reminders, unsubscribe when it
  /// is long past.
  ///
  /// Split out from the fetch so [handleCacheWarm] can feed it launches it
  /// already downloaded as part of the listing, which costs no request at all.
  Future<bool> processLaunch(Launch launch, String launchId) async {
    final launchTitle = launch.name ?? "Unknown";
    final tag = "update:launch:oneoff:$launchId";
    final updateKey = _getUpdateKey("launch", launchId);

    var launchTime = launch.net;
    if (launchTime == null) {
      // If we cannot parse the time, we just try it on the next run
      return true;
    }

    // If we have any updates, we will send them as notification
    try {
      var lastUpdateTime = await _loadDate(updateKey);

      // The first time we hit this, lastUpdateTime is null. We should
      // not send notifications at that point, because the user just clicked the
      // "Receive notifications" button.
      DateTime? oldestUpdateTime;
      if (lastUpdateTime != null) {
        for (var update in launch.updates) {
          if (update.createdOn == null) {
            continue;
          }

          if (update.createdOn!.isAfter(lastUpdateTime) &&
              (update.comment ?? "").isNotEmpty) {
            await notifications!.show(
              id: update.id ?? (update.hashCode.abs()),
              title: launchTitle,
              body: update.comment ?? "No info",
              notificationDetails: _getLaunchUpdateNotifDetails(launchId),
              payload: "$actionLaunchUpdate::$launchId",
            );
          }

          if (oldestUpdateTime == null ||
              update.createdOn!.isAfter(oldestUpdateTime)) {
            oldestUpdateTime = update.createdOn!;
          }
        }
      }

      await _saveDate(updateKey, oldestUpdateTime ?? DateTime.now());
    } catch (err) {
      debugPrint("Error while processing launch updates: $err");
    }

    await _notifyIfDisplayedTimeChanged(
      type: "launch",
      id: launchId,
      title: launchTitle,
      precision: launch.netPrecision,
      at: launch.net,
      details: _getLaunchUpdateNotifDetails(launchId),
      payload: "$actionLaunchUpdate::$launchId",
    );

    final timeSinceLaunch = DateTime.now().difference(launchTime);
    if (timeSinceLaunch > const Duration(hours: 12)) {
      // Cancel this periodic task
      await unsubscribeFromLaunch(launchId);

      return true;
    }

    await _scheduleReminders(
      at: launchTime,
      title: launchTitle,
      noun: "launch",
      where: launch.pad?.location?.name,
      tag: tag,
      details: _getLaunchNotifDetails(tag),
      payload: "$actionLaunchDetails::$launchId",
      idFor: (i) => ((launch.id ?? launchId).hashCode.abs()) + i,
    );

    return true;
  }

  /// Schedules the reminders for one subscription, replacing any already set.
  ///
  /// Identical for launches and events but for the wording and how each
  /// numbers its notifications, which is why [idFor] is a callback: the two
  /// schemes have to stay distinct or one would cancel the other's.
  ///
  /// A reminder whose moment has passed is skipped rather than fired late.
  Future<void> _scheduleReminders({
    required DateTime at,
    required String title,
    required String noun,
    required String? where,
    required String tag,
    required NotificationDetails details,
    required String payload,
    required int Function(int index) idFor,
  }) async {
    final base = tz.TZDateTime.from(at.toUtc(), tz.UTC);
    final now = DateTime.now();

    for (var i = 0; i < reminders.length; i++) {
      final when = base.subtract(reminders[i].before);
      if (when.isBefore(now)) {
        continue;
      }

      final id = idFor(i);

      try {
        await notifications!.cancel(id: id, tag: tag);
      } catch (err) {
        debugPrint("Error cancelling $noun notification $id: $err");
      }

      await _schedule(
        id: id,
        title: title,
        body: _reminderBody(noun, reminders[i].label, where),
        scheduledDate: when,
        notificationDetails: details,
        payload: payload,
      );

      debugPrint("Scheduled a reminder for '$title' at $when");
    }
  }

  /// "This launch will be in 15 minutes · Vandenberg SFB, CA, USA".
  ///
  /// The site earns its place because it is the one thing the title does not
  /// already carry — the title is the rocket and the mission. It is dropped
  /// rather than shortened when the API does not give one.
  static String _reminderBody(String noun, String label, String? where) {
    final body = "This $noun will be in $label";

    return (where ?? "").trim().isEmpty ? body : "$body · $where";
  }

  Future<void> _saveIDs(String key, List<String> values) async {
    var instance = await SharedPreferences.getInstance();
    instance.reload();
    await instance.setStringList(key, values);
  }

  static const launchesKey = "launches";

  static const keywordsKey = "keywords";

  /// Every launch the user has ever unsubscribed from.
  ///
  /// The invariant the keyword feature rests on: unsubscribing is final, and
  /// no keyword may undo it. Without this, taking a launch off the list would
  /// last until the next scan put it straight back.
  static const declinedKey = "auto:declined";

  Future<List<LaunchKeyword>> loadKeywords() async {
    return LaunchKeyword.decode(await _loadString(keywordsKey));
  }

  Future<void> saveKeywords(List<LaunchKeyword> keywords) async {
    await _saveString(keywordsKey, LaunchKeyword.encode(keywords));
  }

  Future<List<String>> loadDeclinedLaunchIDs() => _loadIDs(declinedKey);

  /// What a scan would take on right now, without doing it.
  ///
  /// The same rule the scan uses, so the count on the add screen is what
  /// actually happens rather than a text match that ignores the window.
  Future<List<Launch>> wouldAutoSubscribe(
    List<Launch> launches,
    List<LaunchKeyword> keywords,
  ) async {
    return launchesToAutoSubscribe(
      launches: launches,
      keywords: keywords,
      subscribed: (await _loadIDs(launchesKey)).toSet(),
      declined: (await _loadIDs(declinedKey)).toSet(),
      now: DateTime.now(),
    );
  }

  Future<void> _decline(String launchId) async {
    final declined = await _loadIDs(declinedKey);
    if (declined.contains(launchId)) {
      return;
    }

    declined.add(launchId);
    await _saveIDs(declinedKey, declined);
  }

  /// Subscribes to whatever the keywords have turned up in [launches].
  ///
  /// [notify] is off when the user has just asked for this by adding a
  /// keyword: they are looking at the screen, and thirty-six notifications for
  /// something they pressed a button to do is not news.
  ///
  /// Never prompts: this runs in the background isolate, where there is no UI
  /// to show a permission dialog on. Whatever permissions the user granted
  /// when they subscribed to something by hand are the ones this gets.
  ///
  /// The subscription list is read and written **once**, immediately around
  /// the change, rather than once per launch — the UI isolate may be editing
  /// the same key, and a per-launch read-modify-write would lose whatever it
  /// did in between.
  Future<List<Launch>> scanForKeywordMatches(
    List<Launch> launches, {
    bool notify = true,
  }) async {
    final keywords = await loadKeywords();
    if (keywords.isEmpty) {
      return const [];
    }

    final picked = launchesToAutoSubscribe(
      launches: launches,
      keywords: keywords,
      subscribed: (await _loadIDs(launchesKey)).toSet(),
      declined: (await _loadIDs(declinedKey)).toSet(),
      now: DateTime.now(),
    );

    if (picked.isEmpty) {
      return const [];
    }

    final current = await _loadIDs(launchesKey);
    for (final launch in picked) {
      if (!current.contains(launch.id)) {
        current.add(launch.id!);
      }
    }
    await _saveIDs(launchesKey, current);

    for (final launch in picked) {
      final id = launch.id!;

      try {
        // Before processLaunch, so the updates already on the launch when we
        // found it do not all arrive as notifications.
        await _saveDate(_getUpdateKey("launch", id), DateTime.now());
        await processLaunch(launch, id);

        if (notify) {
          await _notifyAutoSubscribed(launch, id);
        }
      } catch (err) {
        debugPrint("Could not set up the keyword match $id: $err");
      }
    }

    debugPrint("Subscribed to ${picked.length} launch(es) by keyword");

    return picked;
  }

  /// Says what turned up, not what the app did about it.
  ///
  /// "Auto-subscribed" is the implementation talking; the useful thing is
  /// which launch it is and when it goes.
  Future<void> _notifyAutoSubscribed(Launch launch, String id) async {
    final at = launch.net;
    if (at == null || notifications == null) {
      return;
    }

    try {
      await notifications!.show(
        id: "keyword:$id".hashCode.abs(),
        title: launch.name ?? "New launch",
        body: "Will launch on ${_launchWhen(at, launch.netPrecision)}",
        notificationDetails: _getLaunchUpdateNotifDetails(id),
        payload: "$actionLaunchDetails::$id",
      );
    } catch (err) {
      debugPrint("Could not announce the keyword match $id: $err");
    }
  }

  /// A date, and a time only when the API actually knows one.
  static String _launchWhen(DateTime at, DatePrecision? precision) {
    final local = at.toLocal();
    final day = DateFormat("EEE, d MMM y").format(local);

    return switch (precision?.kind) {
      DatePrecisionKind.second ||
      DatePrecisionKind.minute ||
      DatePrecisionKind.hour => "$day at ${DateFormat("HH:mm").format(local)}",
      _ => day,
    };
  }

  Future<bool> isSubscribedToLaunch(String launchId) async {
    var markedIDs = await _loadIDs(launchesKey);
    return markedIDs.contains(launchId);
  }

  Future<List<String>> loadSubscribedLaunchIDs() {
    return _loadIDs(launchesKey);
  }

  Future<void> unsubscribeFromLaunch(String launchId) async {
    // Remove from saved launches
    var markedLaunches = await _loadIDs(launchesKey);
    markedLaunches.remove(launchId);
    await _saveIDs(launchesKey, markedLaunches);

    // Remember it, so no keyword ever puts it back.
    await _decline(launchId);

    try {
      await _deleteKey(_getUpdateKey("launch", launchId));
      await _deleteKey(_getDisplayedTimeKey("launch", launchId));
      // The name this used to be stored under, so an install upgraded
      // from an older build does not leave one behind.
      await _deleteKey("precision:launch:$launchId");
    } catch (err) {
      debugPrint("Deleting update key for launch while unsubscribing: $err");
    }

    // The task an older build registered, plus every near-liftoff check.
    await Workmanager().cancelByUniqueName(_taskNameForLaunch(launchId));

    for (final name in imminentCheckTaskNames(launchId)) {
      await Workmanager().cancelByUniqueName(name);
    }
  }

  String _taskNameForLaunch(String launchId) {
    return "update:launch:$launchId";
  }

  /// Requests what scheduled notifications need. Both are no-ops on Android
  /// versions that grant them at install time.
  ///
  /// `POST_NOTIFICATIONS` (Android 13 / API 33 and up) shows a normal runtime
  /// dialog. `SCHEDULE_EXACT_ALARM` cannot: requesting it sends the user out to
  /// a system settings screen, and from Android 14 (API 34) it is denied by
  /// default. Scheduling has to work whether or not they come back with it.
  Future<void> _ensureNotificationPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // Asked once, ever. Requesting this shows no dialog: it drops the user on
    // a system settings screen with the toggle off, so asking on every
    // subscribe walks them out of the app again and again for a permission
    // they have already declined. The subscription card offers it instead,
    // where it is visible whenever it actually matters.
    if (await exactAlarmsAllowed() || await _hasAskedForExactAlarms()) {
      return;
    }

    await _rememberAskedForExactAlarms();
    await requestExactAlarms();
  }

  static const _askedExactAlarmsKey = "asked-exact-alarms";

  /// Whether reminders can be scheduled to the minute.
  ///
  /// Without this the alarms are inexact, which on API 36 means a one-hour
  /// window (`window=+1h0m0s0ms` in `dumpsys alarm`). An hour is wider than the
  /// gap between all three reminders, so the fifteen- and five-minute ones can
  /// land after the launch has already happened.
  Future<bool> exactAlarmsAllowed() async {
    try {
      return await Permission.scheduleExactAlarm.isGranted;
    } catch (err) {
      debugPrint("Could not check the exact alarm permission: $err");

      return false;
    }
  }

  /// Opens the system screen where exact alarms are turned on.
  Future<void> requestExactAlarms() async {
    try {
      await Permission.scheduleExactAlarm.request();
    } catch (err) {
      debugPrint("Could not request the exact alarm permission: $err");
    }
  }

  Future<bool> _hasAskedForExactAlarms() async {
    try {
      final instance = await SharedPreferences.getInstance();
      await instance.reload();

      return instance.getBool(_askedExactAlarmsKey) ?? false;
    } catch (err) {
      debugPrint("Could not read the exact alarm prompt flag: $err");

      // Better to skip the prompt than to show it on every subscribe.
      return true;
    }
  }

  Future<void> _rememberAskedForExactAlarms() async {
    try {
      final instance = await SharedPreferences.getInstance();
      await instance.reload();

      await instance.setBool(_askedExactAlarmsKey, true);
    } catch (err) {
      debugPrint("Could not store the exact alarm prompt flag: $err");
    }
  }

  /// Which alarm mode to schedule with, given whether exact alarms are allowed.
  ///
  /// An exact alarm without the permission is not a degraded notification, it
  /// is *no* notification: the plugin throws `exact_alarms_not_permitted` and
  /// nothing gets registered. A launch reminder that arrives a few minutes late
  /// is much better than one that never arrives, so fall back to an inexact
  /// alarm instead.
  @visibleForTesting
  static AndroidScheduleMode scheduleModeFor({required bool exactAllowed}) {
    return exactAllowed
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<AndroidScheduleMode> _scheduleMode() async {
    return scheduleModeFor(exactAllowed: await exactAlarmsAllowed());
  }

  /// Schedules one notification, degrading to an inexact alarm rather than
  /// failing when exact alarms are not permitted.
  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required String payload,
  }) async {
    Future<void> withMode(AndroidScheduleMode mode) {
      return notifications!.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: mode,
        payload: payload,
      );
    }

    final mode = await _scheduleMode();

    try {
      await withMode(mode);
    } on PlatformException catch (err) {
      if (mode != AndroidScheduleMode.exactAllowWhileIdle) {
        rethrow;
      }

      // The permission is revocable, so it can disappear between the check
      // above and this call.
      debugPrint("Exact alarm refused ($err), scheduling an inexact one");
      await withMode(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  Future<void> subscribeToLaunch(String launchId) async {
    await _ensureNotificationPermissions();

    var markedLaunches = await _loadIDs(launchesKey);
    if (markedLaunches.contains(launchId)) {
      return;
    }
    // Mark the launch as one we should notify for
    markedLaunches.add(launchId);
    await _saveIDs(launchesKey, markedLaunches);

    await _saveDate(_getUpdateKey("launch", launchId), DateTime.now());

    // No task of its own: `subs:refresh:periodic` picks it up with every other
    // subscription in a single request. Its reminders are scheduled here and
    // now instead, from the cached launch, so they exist before the sheet
    // closes rather than whenever WorkManager first gets round to it. Cache
    // only — subscribing must not spend a request.
    try {
      final cached = await LaunchLibraryAPI().cachedLaunch(launchId);
      if (cached != null) {
        await processLaunch(cached, launchId);
      }
    } catch (err) {
      debugPrint("Could not set up reminders for $launchId yet: $err");
    }
  }

  /*
  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  Event handling goes here
  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  */

  NotificationDetails _getEventNotifDetails(String tag) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'Event Notifications',
        'Event Notifications',
        channelDescription:
            'Notifications for Events, e.g. when a space walk is about to happen.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        tag: tag,
      ),
    );
  }

  NotificationDetails _getEventUpdateNotifDetails(String tag) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'Event Updates',
        'Event Updates',
        channelDescription:
            'Notifications when events are updated, e.g. when a space walk is delayed.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        tag: tag,
      ),
    );
  }

  static const eventsKey = "events";
  Future<bool> isSubscribedToEvent(String eventId) async {
    var markedIDs = await _loadIDs(eventsKey);
    return markedIDs.contains(eventId);
  }

  Future<List<String>> loadSubscribedEventIDs() {
    return _loadIDs(eventsKey);
  }

  Future<void> unsubscribeFromEvent(String eventId) async {
    // Remove from saved events
    var markedEvents = await _loadIDs(eventsKey);
    markedEvents.remove(eventId);
    await _saveIDs(eventsKey, markedEvents);

    try {
      await _deleteKey(_getUpdateKey("event", eventId));
      await _deleteKey(_getDisplayedTimeKey("event", eventId));
      // The name this used to be stored under, so an install upgraded
      // from an older build does not leave one behind.
      await _deleteKey("precision:event:$eventId");
    } catch (err) {
      debugPrint("Deleting update key for event while unsubscribing: $err");
    }

    // Unsubscribe the recurring task
    await Workmanager().cancelByUniqueName(_taskNameForEvent(eventId));
  }

  String _taskNameForEvent(String eventId) {
    return "update:event:$eventId";
  }

  Future<void> subscribeToEvent(String eventId) async {
    await _ensureNotificationPermissions();

    var markedEvents = await _loadIDs(eventsKey);
    if (markedEvents.contains(eventId)) {
      return;
    }
    // Mark the event as one we should notify for
    markedEvents.add(eventId);
    await _saveIDs(eventsKey, markedEvents);

    await _saveDate(_getUpdateKey("event", eventId), DateTime.now());

    // As with launches: no task of its own, and the reminders are set up now
    // from the cached copy rather than on WorkManager's schedule.
    try {
      final id = int.tryParse(eventId);
      final cached = id == null
          ? null
          : await LaunchLibraryAPI().cachedEvent(id);

      if (cached != null) {
        await processEvent(cached, eventId);
      }
    } catch (err) {
      debugPrint("Could not set up reminders for event $eventId yet: $err");
    }
  }

  Future<bool> handleEventUpdatePeriodic(
    Map<String, dynamic>? inputData,
  ) async {
    // At first, we load the associated event
    final eventId = inputData!["eventId"]! as String;

    // If this task was run even though it should not have been, we cancel it
    var markedEvents = await _loadIDs(eventsKey);
    if (!markedEvents.contains(eventId)) {
      await unsubscribeFromEvent(eventId);
      return true;
    }

    return await processEvent(
      (await LaunchLibraryAPI().event(int.parse(eventId))).data,
      eventId,
    );
  }

  /// The event twin of [processLaunch].
  Future<bool> processEvent(Event event, String eventId) async {
    // Adding this offset prevents notifications having the same id (as those of the launch notification)
    const eventNotifIDOffset = 0x0F000000;

    final eventTitle = event.name ?? "Unknown";
    final tag = "update:event:oneoff:$eventId";
    final updateKey = _getUpdateKey("event", eventId);

    var startTime = event.date;
    if (startTime == null) {
      // If we cannot get a time, we just try it on the next run
      return true;
    }

    // If we have any updates, we will send them as notification
    try {
      var lastUpdateTime = await _loadDate(updateKey);

      // The first time we hit this, lastUpdateTime is null. We should
      // not send notifications at that point, because the user just clicked the
      // "Receive notifications" button.
      DateTime? oldestUpdateTime;
      if (lastUpdateTime != null) {
        for (var update in event.updates) {
          if (update.createdOn == null) {
            continue;
          }

          if (update.createdOn!.isAfter(lastUpdateTime) &&
              (update.comment ?? "").isNotEmpty) {
            await notifications!.show(
              id: update.id ?? update.hashCode,
              title: eventTitle,
              body: update.comment ?? "No info",
              notificationDetails: _getEventUpdateNotifDetails(eventId),
              payload: "$actionEventUpdate::$eventId",
            );
          }

          if (oldestUpdateTime == null ||
              update.createdOn!.isAfter(oldestUpdateTime)) {
            oldestUpdateTime = update.createdOn!;
          }
        }
      }

      await _saveDate(updateKey, oldestUpdateTime ?? DateTime.now());
    } catch (err) {
      debugPrint("Error while processing event updates: $err");
    }

    await _notifyIfDisplayedTimeChanged(
      type: "event",
      id: eventId,
      title: eventTitle,
      precision: event.datePrecision,
      at: event.date,
      details: _getEventUpdateNotifDetails(eventId),
      payload: "$actionEventUpdate::$eventId",
    );

    final timeSinceStart = DateTime.now().difference(startTime);
    if (timeSinceStart > const Duration(hours: 12)) {
      // Cancel this periodic task
      await unsubscribeFromEvent(eventId);

      return true;
    }

    await _scheduleReminders(
      at: startTime,
      title: eventTitle,
      noun: "event",
      where: event.location,
      tag: tag,
      details: _getEventNotifDetails(tag),
      payload: "$actionEventDetails::$eventId",
      idFor: (i) =>
          eventNotifIDOffset + (reminders.length * (event.id ?? 0)).abs() + i,
    );

    return true;
  }
}
