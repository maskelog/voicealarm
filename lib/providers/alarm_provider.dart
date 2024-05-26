import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../models/alarm.dart';
import '../utils/alarm_helper.dart';

class AlarmProvider with ChangeNotifier {
  final List<Alarm> _alarms = [];

  List<Alarm> get alarms => _alarms;

  void addAlarm(Alarm alarm) {
    _alarms.add(alarm);
    _scheduleAlarm(alarm);
    notifyListeners();
  }

  void updateAlarm(int index, Alarm alarm) {
    _alarms[index] = alarm;
    _scheduleAlarm(alarm);
    notifyListeners();
  }

  void removeAlarm(int index) {
    AndroidAlarmManager.cancel(_alarms[index].id);
    _alarms.removeAt(index);
    notifyListeners();
  }

  void _scheduleAlarm(Alarm alarm) async {
    final time = TimeOfDay(hour: alarm.time.hour, minute: alarm.time.minute);
    final now = DateTime.now();
    DateTime alarmTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (alarmTime.isBefore(now)) {
      alarmTime = alarmTime.add(const Duration(days: 1));
    }

    final int alarmId = alarm.id.remainder(100000);

    print('Scheduling alarm at $alarmTime with id $alarmId');

    final bool scheduled = await AndroidAlarmManager.oneShotAt(
      alarmTime,
      alarmId,
      AlarmHelper.triggerAlarm,
      exact: true,
      wakeup: true,
    );

    if (scheduled) {
      print('Alarm scheduled successfully');
    } else {
      print('Failed to schedule alarm');
    }
  }
}
