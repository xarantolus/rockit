import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHandler {
  static Future<FlutterLocalNotificationsPlugin> create(ValueNotifier<String> payloadNotification) async {
    var localNotifs = FlutterLocalNotificationsPlugin();

    // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    const androidSettings = AndroidInitializationSettings('notification_icon');
    const initSettings = InitializationSettings(android: androidSettings);

    var success = await localNotifs.initialize(
      initSettings,
      onSelectNotification: (payload) {
        if (payload != null) {
          payloadNotification.value = payload;
        }
      },
    );
    if (success == false) {
      throw Exception("Could not initialize local notification plugin");
    }

    var initialPayload = await localNotifs.getNotificationAppLaunchDetails();
    if (initialPayload?.payload != null) {
      payloadNotification.value = initialPayload!.payload!;
    }

    return localNotifs;
  }
}
