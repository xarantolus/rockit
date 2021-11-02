import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rockit/apis/launch_library/api.dart';
import 'package:rockit/notifications/create.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

// This function will be called by Android when a task should be run
void backgroundTaskCallback() {
  Workmanager().executeTask((task, inputData) {
    var handler = BackgroundHandler();

    return handler.callback(task, inputData);
  });
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
        ticker: 'ticker',
        tag: tag,
      ),
    );
  }

  // Return true for successful tasks, false for failed tasks that need to be retried
  // and Future.error() for tasks that failed and don't need to be retried
  Future<bool> callback(String task, Map<String, dynamic>? inputData) {
    switch (task) {
      case periodicLaunchUpdateTaskName:
        return handleLaunchUpdatePeriodic(inputData);
      default:
    }
    return Future.value(true);
  }

  Future<List<String>> _loadIDs(String key) async {
    try {
      return (await SharedPreferences.getInstance()).getStringList(key) ?? [];
    } catch (_) {}
    return [];
  }

  Future<bool> handleLaunchUpdatePeriodic(
      Map<String, dynamic>? inputData) async {
    // At first, we load the associated launch
    final launchId = inputData!["launchId"]!;
    final launch = await LaunchLibraryAPI().launch(launchId);

    var launchTime = DateTime.tryParse(launch.net ?? "");
    if (launchTime == null) {
      return true;
    }

    final launchTitle = launch.name ?? "Unknown";
    final tag = "update:launch:oneoff:$launchId";

    // Now we can just register all notifications for this launch

    var x = (await NotificationHandler.create()).notifs;

    x.show(31, "Background task for $launchTitle",
        "Running background notif scheduler", _getNotifDetails(tag));

    // Cancel all previously registered ones
    try {
      x.cancel(1, tag: tag);
      x.cancel(2, tag: tag);
      x.cancel(3, tag: tag);
    } catch (_) {}

    if (launchTime.isBefore(DateTime.now())) {
      // Cancel this periodic task

      x.show(32, "Background task for $launchTitle",
          "Cancelled notif scheduler", _getNotifDetails(tag));

      Workmanager().cancelByTag("update:launch:slow:$launchId");
      return true;
    }

    // And now register all notifications
    var notifBaseTime = tz.TZDateTime.utc(
        launchTime.year,
        launchTime.month,
        launchTime.day,
        launchTime.hour,
        launchTime.minute,
        launchTime.second,
        launchTime.millisecond,
        launchTime.microsecond);

    x.zonedSchedule(
      1,
      launchTitle,
      "This start will be in 1h",
      notifBaseTime.add(const Duration(hours: -1)),
      _getNotifDetails(tag),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle: true,
    );

    x.zonedSchedule(
      2,
      launchTitle,
      "This start will be in 15 minutes",
      notifBaseTime.add(const Duration(minutes: 15)),
      _getNotifDetails(tag),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle: true,
    );

    x.zonedSchedule(
      3,
      launchTitle,
      "This start will be in 5 minutes",
      notifBaseTime.add(const Duration(minutes: 5)),
      _getNotifDetails(tag),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle: true,
    );

    x.show(33, "Background task for $launchTitle", "Rescheduled notifications",
        _getNotifDetails(tag));

    return true;
  }

  Future<void> _saveIDs(String key, List<String> values) async {
    await (await SharedPreferences.getInstance()).setStringList(key, values);
  }

  static const launchesKey = "launches";

  Future<bool> isSubscribedToLaunch(String launchId) async {
    return (await _loadIDs(launchesKey)).contains(launchId);
  }

  Future<void> unsubscribeFromLaunch(String launchId) async {
    // Unsubscribe the recurring task
    await Workmanager().cancelByUniqueName("update:launch:$launchId");

    // Remove from saved launches
    var markedLaunches = await _loadIDs(launchesKey);
    if (!markedLaunches.contains(launchId)) {
      return;
    }
    markedLaunches.remove(launchId);
    await _saveIDs(launchesKey, markedLaunches);
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
      "update:launch:$launchId",
      periodicLaunchUpdateTaskName,
      tag: "update:launch:slow:$launchId",
      frequency: const Duration(hours: 1),
      inputData: {
        "launchId": launchId,
      },
    );
  }
}
