import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_voice_alarm/models/model.dart';
import 'package:timezone/timezone.dart' as tz;

class AlarmHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: AndroidInitializationSettings('app_icon'),
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> scheduleAlarm(Model alarmModel) async {
    DateTime dateTime =
        DateTime.fromMillisecondsSinceEpoch(alarmModel.milliseconds);
    tz.TZDateTime tzDateTime = tz.TZDateTime.from(dateTime, tz.local);

    // 현재 시간보다 알람 시간이 이전이라면, 알람을 다음 날로 설정
    if (tzDateTime.isBefore(DateTime.now())) {
      tzDateTime = tzDateTime.add(const Duration(days: 1));
    }

    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'alarm_channel',
      '알람',
      channelDescription: '알람을 위한 채널',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'app_icon',
    );

    const platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    // 32비트 정수 범위 내의 알람 ID 생성
    final int alarmId = alarmModel.id % 0x7FFFFFFF;

    await _notificationsPlugin.zonedSchedule(
      alarmId,
      alarmModel.label,
      '알람이 울립니다',
      tzDateTime,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelAlarm(int alarmId) async {
    await _notificationsPlugin.cancel(alarmId % 0x7FFFFFFF);
  }
}
