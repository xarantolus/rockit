import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHandler {
  static Future<FlutterLocalNotificationsPlugin> create([ValueNotifier<String>? payloadNotification]) async {
    var localNotifs = FlutterLocalNotificationsPlugin();

    // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    const androidSettings = AndroidInitializationSettings('notification_icon');
    const initSettings = InitializationSettings(android: androidSettings);

    var success = await localNotifs.initialize(
      initSettings,
      onDidReceiveNotificationResponse: payloadNotification == null
          ? null
          : (payload) {
              if (payload.payload != null) {
                // If it's the same value as before, we still want to notify.
                // So we just set it to empty (listeners won't do anything),
                // then we set the value again. This is kind of ugly, but works fine
                payloadNotification.value = "";
                payloadNotification.value = payload.payload!;
              }
            },
    );
    if (success == false) {
      throw Exception("Could not initialize local notification plugin");
    }

    if (payloadNotification != null) {
      var initialPayload = await localNotifs.getNotificationAppLaunchDetails();
      if (initialPayload?.notificationResponse?.payload != null) {
        payloadNotification.value = initialPayload!.notificationResponse!.payload!;
      }
    }

    return localNotifs;
  }
}
