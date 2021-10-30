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
  BackgroundHandler._internal();

  // Return true for successful tasks, false for failed tasks that need to be retried
  // and Future.error() for tasks that failed and don't need to be retried
  Future<bool> callback(String task, Map<String, dynamic>? inputData) {
    return Future.value(true);
  }

  // TODO: Register notifications for a rocket launch (maybe only register if the first launch http request was successful, to make sure it was cached?)

  // TODO: Periodically update rocket launch update time intervals, then cancel all other registered tasks (using a tag for each launch)
}
