import 'package:flutter_alarm_clock/model/model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class AlarmHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: AndroidInitializationSettings('app_icon'), // 앱 아이콘 설정
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> scheduleAlarm(Model alarmModel) async {
    final DateTime dateTime =
        DateTime.fromMillisecondsSinceEpoch(alarmModel.milliseconds);
    final tz.TZDateTime tzDateTime = tz.TZDateTime.from(dateTime, tz.local);

    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'alarm_channel', // channel id
      '알람', // channel name
      channelDescription: '알람을 위한 채널', // channel description
      importance: Importance.max,
      priority: Priority.high,
      icon: 'app_icon', // 알람 아이콘 설정
    );

    const platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.zonedSchedule(
      alarmModel.id,
      alarmModel.label,
      '알람이 울립니다',
      tzDateTime,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
