import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHandler {
  static Future<FlutterLocalNotificationsPlugin> create() async {
    var localNotifs = FlutterLocalNotificationsPlugin();

    // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    const androidSettings = AndroidInitializationSettings('notification_icon');
    const initSettings = InitializationSettings(android: androidSettings);

    var success = await localNotifs.initialize(initSettings);
    if (success == false) {
      throw Exception("Could not initialize local notification plugin");
    }

    return localNotifs;
  }
}
