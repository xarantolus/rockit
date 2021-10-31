import 'package:rockit/apis/launch_library/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  BackgroundHandler._internal();

  // Return true for successful tasks, false for failed tasks that need to be retried
  // and Future.error() for tasks that failed and don't need to be retried
  Future<bool> callback(String task, Map<String, dynamic>? inputData) {
    switch (task) {
      case "update:launch:periodic":
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

    final tag = "update:launch:oneoff:$launchId";

    // Now we can just register all notifications for this launch

    // TODO: Stuff etc

    return true;
  }

  Future<void> _saveIDs(String key, List<String> values) async {
    await (await SharedPreferences.getInstance()).setStringList(key, values);
  }

  static const launchesKey = "launches";

  Future<bool> isLaunchMarked(String launchId) async {
    return (await _loadIDs(launchesKey)).contains(launchId);
  }

  Future<void> markRocketLaunch(String launchId) async {
    var markedLaunches = await _loadIDs(launchesKey);
    if (markedLaunches.contains(launchId)) {
      return;
    }

    // Request the launch to make sure it exists & to get info.
    // This also makes sure that this launch is cached from now on
    var launch = await LaunchLibraryAPI().launch(launchId);

    // Mark the launch as one we should notify for
    markedLaunches.add(launchId);
    await _saveIDs(launchesKey, markedLaunches);

    // Now tell the work manager to do periodic updates for this launch
    await Workmanager().registerPeriodicTask(
      "updates:launch:$launchId",
      "update:launch:periodic",
      tag: "update:launch:slow:$launchId",
      frequency: const Duration(hours: 1),
      inputData: {
        "launchId": launch.id,
      },
    );
  }
}
