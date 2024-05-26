import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AlarmHelper {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
<<<<<<< HEAD
        AndroidInitializationSettings('@mipmap/ic_launcher');
=======
        AndroidInitializationSettings('app_icon');
>>>>>>> 81c1d75c471c75690eb66eda1da85c3757d6e84a

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

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
      'Alarm Channel',
      channelDescription: 'Channel for Alarm notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
      fullScreenIntent: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      id,
      '알람',
      '알람이 울립니다!',
      platformChannelSpecifics,
      payload: 'Alarm payload',
    );

    print('Alarm notification should be shown now');
  }
}
