import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rockit/apis/launch_library/api.dart';
import 'package:rockit/notifications/create.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

// This function will be called by Android when a task should be run
void backgroundTaskCallback() {
  Workmanager().executeTask((task, inputData) async {
    var handler = BackgroundHandler();

    return await handler.callback(task, inputData);
  });
}

class _NotifSetting {
  final Duration offset;
  final String displayed;

  const _NotifSetting(this.offset, this.displayed);
}

class BackgroundHandler {
  static final instance = BackgroundHandler._internal();
  factory BackgroundHandler() {
    return instance;
  }
  BackgroundHandler._internal() {
    tz.initializeTimeZones();
  }

  static const periodicLaunchUpdateTaskName = "update:launch:periodic";

  NotificationDetails _getNotifDetails(String tag) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'Rocket Launch Notifications',
        'Rocket Launch Notifications',
        channelDescription:
            'Notifications for Rocket launches, e.g. when a launch is about to happen.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        tag: tag,
      ),
    );
  }

  // Return true for successful tasks, false for failed tasks that need to be retried
  // and Future.error() for tasks that failed and don't need to be retried
  Future<bool> callback(String task, Map<String, dynamic>? inputData) async {
    switch (task) {
      case periodicLaunchUpdateTaskName:
        return await handleLaunchUpdatePeriodic(inputData);
      default:
    }
    return true;
  }

  Future<List<String>> _loadIDs(String key) async {
    try {
      var instance = await SharedPreferences.getInstance();
      await instance.reload();
      return instance.getStringList(key) ?? [];
    } catch (_) {}
    return [];
  }

  Future<bool> handleLaunchUpdatePeriodic(
      Map<String, dynamic>? inputData) async {
    // At first, we load the associated launch
    final launchId = inputData!["launchId"]!;

    // If this task was run even though it should not have been, we cancel it
    var markedLaunches = await _loadIDs(launchesKey);
    if (!markedLaunches.contains(launchId)) {
      await unsubscribeFromLaunch(launchId);
      return true;
    }

    final launch = await LaunchLibraryAPI().launch(launchId);

    final launchTitle = launch.name ?? "Unknown";
    final tag = "update:launch:oneoff:$launchId";

    var notifs = await NotificationHandler.create();

    var launchTime = DateTime.tryParse(launch.net ?? "");
    if (launchTime == null) {
      // If we cannot parse the time, we just try it on the next run
      return true;
    }

    // Now we can just register all notifications for this launch
    const notificationSettings = [
      _NotifSetting(Duration(hours: -1), "one hour"),
      _NotifSetting(Duration(minutes: -15), "15 minutes"),
      _NotifSetting(Duration(minutes: -5), "5 minutes"),
    ];

    // Cancel all previously registered ones
    try {
      for (var i = 0; i < notificationSettings.length; i++) {
        await notifs.cancel(i, tag: tag);
      }
    } catch (_) {}

    if (launchTime.isBefore(DateTime.now())) {
      // Cancel this periodic task
      await unsubscribeFromLaunch(launchId);
      return true;
    }

    // And now register all notifications
    var notifBaseTime = tz.TZDateTime.from(launchTime.toUtc(), tz.UTC);

    var now = DateTime.now();
    // Register notifications with their offsets
    for (var i = 0; i < notificationSettings.length; i++) {
      Duration offset = notificationSettings[i].offset;

      var notifTime = notifBaseTime.add(offset);
      if (notifTime.isBefore(now)) {
        continue;
      }

      await notifs.zonedSchedule(
        i,
        launchTitle,
        "This launch will be in ${notificationSettings[i].displayed}",
        notifTime,
        _getNotifDetails(tag),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidAllowWhileIdle: true,
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

  Future<void> unsubscribeFromLaunch(String launchId) async {
    // Remove from saved launches
    var markedLaunches = await _loadIDs(launchesKey);
    markedLaunches.remove(launchId);
    await _saveIDs(launchesKey, markedLaunches);

    // Unsubscribe the recurring task
    await Workmanager().cancelByUniqueName(_taskNameForLaunch(launchId));
  }

  String _taskNameForLaunch(String launchId) {
    return "update:launch:$launchId";
  }

  Future<void> subscribeToLaunch(String launchId) async {
    var markedLaunches = await _loadIDs(launchesKey);
    if (markedLaunches.contains(launchId)) {
      return;
    }
    // Mark the launch as one we should notify for
    markedLaunches.add(launchId);
    await _saveIDs(launchesKey, markedLaunches);

    // Now tell the work manager to do periodic updates for this launch
    await Workmanager().registerPeriodicTask(
      _taskNameForLaunch(launchId),
      periodicLaunchUpdateTaskName,
      frequency: const Duration(hours: 1),
      inputData: {
        "launchId": launchId,
      },
    );
  }
}
