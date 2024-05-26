import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../screens/full_screen_alarm.dart';

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

    final bool? initialized = await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Alarm notification tapped action
        _showFullScreenAlarm();
      },
    );

    if (initialized != null && initialized) {
      print('Notifications initialized successfully');
    } else {
      print('Failed to initialize notifications');
    }
  }

  static Future<void> triggerAlarm(int id) async {
    print('Triggering alarm with id $id at ${DateTime.now()}');
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
      fullScreenIntent: true, // Ensures full-screen intent
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    try {
      await flutterLocalNotificationsPlugin.show(
        id,
        '알람',
        '설정된 알람이 울립니다!',
        platformChannelSpecifics,
        payload: 'AlarmPayload', // Custom payload to identify the alarm
      );
      print('Alarm notification shown successfully');
    } catch (e) {
      print('Failed to show alarm notification: $e');
    }
  }

  static void _showFullScreenAlarm() {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(const MaterialApp(
      home: FullScreenAlarmScreen(),
      debugShowCheckedModeBanner: false,
    ));
  }
}
