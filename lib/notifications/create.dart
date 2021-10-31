import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHandler {
  FlutterLocalNotificationsPlugin _localNotifs;

  NotificationHandler._create(this._localNotifs);

  static create() async {
    var localNotifs = FlutterLocalNotificationsPlugin();

    // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    var success = await localNotifs.initialize(initSettings);
    if (success == false) {
      throw Exception("Could not initialize local notification plugin");
    }

    return NotificationHandler._create(localNotifs);
  }

  void clearAllForTag(String tag) {
    _localNotifs.
  }

  void createNotification() {
    _localNotifs.zonedSchedule(id, title, body, scheduledDate, notificationDetails, uiLocalNotificationDateInterpretation: uiLocalNotificationDateInterpretation, androidAllowWhileIdle: androidAllowWhileIdle)

  }
}
