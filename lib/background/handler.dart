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
    final launch = await LaunchLibraryAPI().launch(launchId);

    final launchTitle = launch.name ?? "Unknown";
    final tag = "update:launch:oneoff:$launchId";

    var x = (await NotificationHandler.create()).notifs;

    var launchTime = DateTime.tryParse(launch.net ?? "");
    if (launchTime == null) {
      await x.show(35, "Background task for $launchTitle",
          "Cannot parse launch time", _getNotifDetails(tag));
      return true;
    }

    // Now we can just register all notifications for this launch

    await x.show(31, "Background task for $launchTitle",
        "Running background notif scheduler", _getNotifDetails(tag));

    const notificationSettings = [
      _NotifSetting(Duration(hours: -1), "one hour"),
      _NotifSetting(Duration(minutes: -15), "15 minutes"),
      _NotifSetting(Duration(minutes: -5), "5 minutes"),
    ];

    // Cancel all previously registered ones
    try {
      for (var i = 0; i < notificationSettings.length; i++) {
        await x.cancel(i, tag: tag);
      }
    } catch (_) {}

    if (launchTime.isBefore(DateTime.now())) {
      // Cancel this periodic task

      // TODO: Only cancel if the launch time has been more than x hours ago, e.g. in case of a scrub
      // we still want to stay subscribed

      await x.show(32, "Background task for $launchTitle",
          "Cancelled notif scheduler", _getNotifDetails(tag));

      await unsubscribeFromLaunch(launchId);
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

    var now = DateTime.now();
    // Register notifications with their offsets
    for (var i = 0; i < notificationSettings.length; i++) {
      Duration offset = notificationSettings[i].offset;
      var notifTime = notifBaseTime.add(offset);
      if (notifTime.isBefore(now)) {
        await x.show(36, "Background task for $launchTitle",
            "$notifTime is before now", _getNotifDetails(tag));
        continue;
      }

      await x.zonedSchedule(
        i,
        launchTitle,
        "This start will be in ${notificationSettings[i].displayed}",
        notifTime,
        _getNotifDetails(tag),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidAllowWhileIdle: true,
      );
    }

    await x.show(33, "Background task for $launchTitle",
        "Rescheduled notifications", _getNotifDetails(tag));

    return true;
  }

  Future<void> _saveIDs(String key, List<String> values) async {
    var instance = await SharedPreferences.getInstance();
    instance.reload();
    await instance.setStringList(key, values);
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
