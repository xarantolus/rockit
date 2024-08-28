import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rockit/apis/launch_library/api.dart';
import 'package:rockit/notifications/create.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

// This function will be called by Android when a task should be run
void backgroundTaskCallback() {
  // Overwrite debug print logic
  final oldDebugPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    oldDebugPrint("xarantolus${kDebugMode ? '.debug' : ''}.rockit: " + (message ?? "No message"), wrapWidth: wrapWidth);
  };

  Workmanager().executeTask((task, inputData) async {
    var handler = BackgroundHandler.withNotifications(await NotificationHandler.create());

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
      throw Exception("BackgroundHandler() initialized when instance notification plugin was null");
    }
    return instance!;
  }

  BackgroundHandler._internal(this.notifications) {
    tz.initializeTimeZones();
  }

  static const periodicLaunchUpdateTaskName = "update:launch:periodic";
  static const periodicEventUpdateTaskName = "update:event:periodic";

  final _periodicTaskConstraints = Constraints(
    networkType: NetworkType.connected,
  );

  NotificationDetails _getLaunchNotifDetails(String tag) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'Rocket Launch Notifications',
        'Rocket Launch Notifications',
        channelDescription: 'Notifications for rocket launches, e.g. when a launch is about to happen.',
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
        default:
          throw FormatException("Expected task name to be for event or update, but got \"$task\"");
      }
    } catch (err) {
      debugPrint("Error in scheduled task: $err");
      rethrow;
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

  String _getUpdateKey(String type, String id) {
    return "update:$type:lastupdate:$id";
  }

  Future<bool> handleLaunchUpdatePeriodic(Map<String, dynamic>? inputData) async {
    // At first, we load the associated launch
    final launchId = inputData!["launchId"]!;

    // If this task was run even though it should not have been, we cancel it
    var markedLaunches = await _loadIDs(launchesKey);
    if (!markedLaunches.contains(launchId)) {
      await unsubscribeFromLaunch(launchId);
      return true;
    }

    final launch = (await LaunchLibraryAPI().launch(launchId)).data;

    final launchTitle = launch.name ?? "Unknown";
    final tag = "update:launch:oneoff:$launchId";
    final updateKey = _getUpdateKey("launch", launchId);

    var launchTime = DateTime.tryParse(launch.net ?? "");
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
      if (lastUpdateTime != null && launch.updates != null) {
        for (var update in launch.updates!) {
          if (update.createdOn == null) {
            continue;
          }

          if (update.createdOn!.isAfter(lastUpdateTime) && (update.comment ?? "").isNotEmpty) {
            await notifications!.show(
              update.id ?? (update.hashCode.abs()),
              launchTitle,
              update.comment ?? "No info",
              _getLaunchUpdateNotifDetails(launchId),
              payload: "$actionLaunchDetails::$launchId",
            );
          }

          if (oldestUpdateTime == null || update.createdOn!.isAfter(oldestUpdateTime)) {
            oldestUpdateTime = update.createdOn!;
          }
        }
      }

      await _saveDate(updateKey, oldestUpdateTime ?? DateTime.now());
    } catch (err) {
      debugPrint("Error while processing launch updates: $err");
    }

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
        await notifications!.cancel(notifID, tag: tag);
      } catch (err) {
        debugPrint("Error cancelling launch notification $notifID: $err");
      }

      await notifications!.zonedSchedule(
        notifID,
        launchTitle,
        "This launch will be in ${notificationSettings[i].displayed}",
        notifTime,
        _getLaunchNotifDetails(tag),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidAllowWhileIdle: true,
        payload: "$actionLaunchDetails::$launchId",
      );
      debugPrint("Scheduled notification for event '$launchTitle' for $notifTime");
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
    } catch (err) {
      debugPrint("Deleting update key for launch while unsubscribing: $err");
    }

    // Unsubscribe the recurring task
    await Workmanager().cancelByUniqueName(_taskNameForLaunch(launchId));
  }

  String _taskNameForLaunch(String launchId) {
    return "update:launch:$launchId";
  }

  Future<void> subscribeToLaunch(String launchId) async {
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }

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
      inputData: {
        "launchId": launchId,
      },
      existingWorkPolicy: ExistingWorkPolicy.replace,
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
        channelDescription: 'Notifications for Events, e.g. when a space walk is about to happen.',
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
        channelDescription: 'Notifications when events are updated, e.g. when a space walk is delayed.',
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
      inputData: {
        "eventId": eventId,
      },
      existingWorkPolicy: ExistingWorkPolicy.replace,
      constraints: _periodicTaskConstraints,
    );
  }

  Future<bool> handleEventUpdatePeriodic(Map<String, dynamic>? inputData) async {
    // Adding this offset prevents notifications having the same id (as those of the launch notification)
    const eventNotifIDOffset = 0x0F000000;

    // At first, we load the associated event
    final eventId = inputData!["eventId"]! as String;

    // If this task was run even though it should not have been, we cancel it
    var markedEvents = await _loadIDs(eventsKey);
    if (!markedEvents.contains(eventId)) {
      await unsubscribeFromEvent(eventId);
      return true;
    }

    final event = (await LaunchLibraryAPI().event(eventId)).data;

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
      if (lastUpdateTime != null && event.updates != null) {
        for (var update in event.updates!) {
          if (update.createdOn == null) {
            continue;
          }

          if (update.createdOn!.isAfter(lastUpdateTime) && (update.comment ?? "").isNotEmpty) {
            await notifications!.show(
              update.id ?? update.hashCode,
              eventTitle,
              update.comment ?? "No info",
              _getEventUpdateNotifDetails(eventId),
              payload: "$actionEventDetails::$eventId",
            );
          }

          if (oldestUpdateTime == null || update.createdOn!.isAfter(oldestUpdateTime)) {
            oldestUpdateTime = update.createdOn!;
          }
        }
      }

      await _saveDate(updateKey, oldestUpdateTime ?? DateTime.now());
    } catch (err) {
      debugPrint("Error while processing event updates: $err");
    }

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

      final notifID = eventNotifIDOffset + (notificationSettings.length * event.id).abs() + i;

      // Cancel the previously scheduled notification (if possible)
      try {
        await notifications!.cancel(notifID, tag: tag);
      } catch (err) {
        debugPrint("Error cancelling event notification $notifID: $err");
      }

      await notifications!.zonedSchedule(
        notifID,
        eventTitle,
        "This event will be in ${notificationSettings[i].displayed}",
        notifTime,
        _getEventNotifDetails(tag),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidAllowWhileIdle: true,
        payload: "$actionEventDetails::$eventId",
      );
      debugPrint("Scheduled notification for event '$eventTitle' for $notifTime");
    }

    return true;
  }
}
