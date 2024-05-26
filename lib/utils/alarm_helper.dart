import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AlarmHelper {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    final bool? initialized = await flutterLocalNotificationsPlugin
        .initialize(initializationSettings);
    if (initialized != null && initialized) {
      print('Notifications initialized successfully');
    } else {
      print('Failed to initialize notifications');
    }
  }

  static Future<void> triggerAlarm(int id) async {
    print('Triggering alarm with id $id');
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'alarm_channel',
      'Alarm Notifications',
      channelDescription: 'Channel for Alarm notifications',
      importance: Importance.high,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      '알람',
      '설정된 알람이 울립니다!',
      platformChannelSpecifics,
    );

    print('Alarm notification should be shown now');
  }
}
