import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rockit/apis/launch_library/api.dart';
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

class _NotifSetting {
  final Duration offset;
  final String displayed;

  const _NotifSetting(this.offset, this.displayed);
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
  static const periodicCacheWarmTaskName = "cache:warm:periodic";
  static const _cacheWarmTaskId = "cache-warm";

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
        case periodicCacheWarmTaskName:
          return await handleCacheWarm();
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
    } catch (err) {
      debugPrint("Could not schedule cache warming: $err");
    }
  }

  /// Fetches the first page of launches, events and news purely for the cache.
  ///
  /// This runs in a background isolate, but it is the same app: the HTTP cache
  /// is one directory on disk, so what this stores is what the UI reads back.
  /// (If the app happens to be in the foreground at the same time, the two
  /// isolates can overwrite each other's cache *index*; the response files
  /// survive, so the worst case is a cache miss, not bad data.)
  Future<bool> handleCacheWarm() async {
    final api = LaunchLibraryAPI();

    // In parallel: this API regularly takes ten seconds a request and the
    // three are independent, so there is no reason to add them up.
    final results = await Future.wait([
      _warmCache("launches", () async {
        final launches = (await api.upcomingLaunches()).data.results;
        await _refreshSubscriptionsFrom(launches: launches);
      }),
      _warmCache("events", () async {
        final events = (await api.upcomingEvents()).data.results;
        await _refreshSubscriptionsFrom(events: events);
      }),
      _warmCache("news", () => SpaceFlightNewsAPI().articles()),
    ]);

    // Returning false asks WorkManager to run the whole task again. That is
    // only right when nothing worked; one dead endpoint should not make us
    // re-spend requests on the two that succeeded.
    return results.any((ok) => ok);
  }

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

  String _getPrecisionKey(String type, String id) => "precision:$type:$id";

  /// Notifies once a date stops being a guess.
  ///
  /// Only entries in the API's update feed produce a notification, and the
  /// change a subscriber most wants is often not in it: a launch going from
  /// "NET October" to an actual time. The reminders quietly start working at
  /// that point and nobody is told.
  ///
  /// Deliberately only that one transition. A [net] that drifts by hours, or a
  /// precision that gets *vaguer*, happens constantly for unconfirmed launches
  /// and would be noise.
  Future<void> _notifyIfTimeBecameKnown({
    required String type,
    required String id,
    required String title,
    required DatePrecision? precision,
    required DateTime? at,
    required NotificationDetails details,
    required String payload,
  }) async {
    final key = _getPrecisionKey(type, id);
    final previous = await _loadString(key);

    await _saveString(key, precision?.abbrev ?? "");

    // Nothing to compare against on the first run, which is the moment the
    // user subscribed.
    if (previous == null || at == null) {
      return;
    }

    if (!timeBecameKnown(DatePrecision(abbrev: previous), precision)) {
      return;
    }

    try {
      await notifications!.show(
        id: "time:$id".hashCode.abs(),
        title: title,
        body:
            "A launch time has been set: "
            "${DateFormat("EEE, d MMM y, HH:mm").format(at.toLocal())}",
        notificationDetails: details,
        payload: payload,
      );
    } catch (err) {
      debugPrint("Could not notify about the new time for $id: $err");
    }
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

    await _notifyIfTimeBecameKnown(
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

    // Now we can just register all notifications for this launch
    const notificationSettings = [
      _NotifSetting(Duration(hours: -1), "one hour"),
      _NotifSetting(Duration(minutes: -15), "15 minutes"),
      _NotifSetting(Duration(minutes: -5), "5 minutes"),
    ];

    var notifBaseTime = tz.TZDateTime.from(launchTime.toUtc(), tz.UTC);

    var now = DateTime.now();
    // Register notifications with their offsets
    for (var i = 0; i < notificationSettings.length; i++) {
      Duration offset = notificationSettings[i].offset;

      final notifID = ((launch.id ?? launchId).hashCode.abs()) + i;

      var notifTime = notifBaseTime.add(offset);
      if (notifTime.isBefore(now)) {
        continue;
      }

      // Cancel the previously scheduled notification (if possible)
      try {
        await notifications!.cancel(id: notifID, tag: tag);
      } catch (err) {
        debugPrint("Error cancelling launch notification $notifID: $err");
      }

      await _schedule(
        id: notifID,
        title: launchTitle,
        body: "This launch will be in ${notificationSettings[i].displayed}",
        scheduledDate: notifTime,
        notificationDetails: _getLaunchNotifDetails(tag),
        payload: "$actionLaunchDetails::$launchId",
      );
      debugPrint(
        "Scheduled notification for event '$launchTitle' for $notifTime",
      );
    }

    return true;
  }

  Future<void> _saveIDs(String key, List<String> values) async {
    var instance = await SharedPreferences.getInstance();
    instance.reload();
    await instance.setStringList(key, values);
  }

  static const launchesKey = "launches";

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

    try {
      await _deleteKey(_getUpdateKey("launch", launchId));
      await _deleteKey(_getPrecisionKey("launch", launchId));
    } catch (err) {
      debugPrint("Deleting update key for launch while unsubscribing: $err");
    }

    // Unsubscribe the recurring task
    await Workmanager().cancelByUniqueName(_taskNameForLaunch(launchId));
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

    // Now tell the work manager to do periodic updates for this launch
    await Workmanager().registerPeriodicTask(
      _taskNameForLaunch(launchId),
      periodicLaunchUpdateTaskName,
      frequency: const Duration(hours: 1),
      inputData: {"launchId": launchId},
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      constraints: _periodicTaskConstraints,
    );
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
      await _deleteKey(_getPrecisionKey("event", eventId));
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

    // Now tell the work manager to do periodic updates for this launch
    await Workmanager().registerPeriodicTask(
      _taskNameForEvent(eventId),
      periodicEventUpdateTaskName,
      frequency: const Duration(hours: 1),
      inputData: {"eventId": eventId},
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      constraints: _periodicTaskConstraints,
    );
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

    await _notifyIfTimeBecameKnown(
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

    // Now we can just register all notifications for this event
    const notificationSettings = [
      _NotifSetting(Duration(hours: -1), "one hour"),
      _NotifSetting(Duration(minutes: -15), "15 minutes"),
      _NotifSetting(Duration(minutes: -5), "5 minutes"),
    ];

    // And now register all notifications
    var notifBaseTime = tz.TZDateTime.from(startTime.toUtc(), tz.UTC);

    var now = DateTime.now();
    // Register notifications with their offsets
    for (var i = 0; i < notificationSettings.length; i++) {
      Duration offset = notificationSettings[i].offset;

      var notifTime = notifBaseTime.add(offset);
      if (notifTime.isBefore(now)) {
        continue;
      }

      final notifID =
          eventNotifIDOffset +
          (notificationSettings.length * (event.id ?? 0)).abs() +
          i;

      // Cancel the previously scheduled notification (if possible)
      try {
        await notifications!.cancel(id: notifID, tag: tag);
      } catch (err) {
        debugPrint("Error cancelling event notification $notifID: $err");
      }

      await _schedule(
        id: notifID,
        title: eventTitle,
        body: "This event will be in ${notificationSettings[i].displayed}",
        scheduledDate: notifTime,
        notificationDetails: _getEventNotifDetails(tag),
        payload: "$actionEventDetails::$eventId",
      );
      debugPrint(
        "Scheduled notification for event '$eventTitle' for $notifTime",
      );
    }

    return true;
  }
}
