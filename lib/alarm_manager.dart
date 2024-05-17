import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_voice_alarm/alarm_info.dart';
import 'package:flutter_voice_alarm/weather_service.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

class AlarmManager {
  final WeatherService weatherService;
  final AudioPlayer audioPlayer = AudioPlayer();

  AlarmManager(this.weatherService);

  Future<void> scheduleAlarm(AlarmInfo alarm) async {
    DateTime scheduleDate = DateTime(alarm.date.year, alarm.date.month,
        alarm.date.day, alarm.time.hour, alarm.time.minute);
    await AndroidAlarmManager.oneShotAt(
        scheduleDate,
        alarm.id, // Unique ID for each alarm
        checkAlarmCallback,
        alarmClock: true,
        wakeup: true,
        exact: true,
        rescheduleOnReboot: true);
    // 알람을 스케줄링한 후 알람을 저장
    List<AlarmInfo> alarms = await loadAlarms();
    alarms.add(alarm);
    await saveAlarms(alarms);
  }

  static Future<void> checkAlarmCallback(int id) async {
    // Fetch alarm details from shared preferences or other storage
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> alarmStrings = prefs.getStringList('alarms') ?? [];
    List<AlarmInfo> alarms = alarmStrings
        .map((alarmString) => AlarmInfo.fromJson(jsonDecode(alarmString)))
        .toList();

    // Fetch the triggered alarm
    AlarmInfo? triggeredAlarm;
    for (var alarm in alarms) {
      if (alarm.id == id && alarm.isEnabled) {
        triggeredAlarm = alarm;
        break;
      }
    }

    if (triggeredAlarm != null) {
      // Play alarm sound
      AudioPlayer audioPlayer = AudioPlayer();
      await audioPlayer.play(AssetSource('assets/sounds/alarm_sound.ogg'));

      // Show alarm ringing screen (this might need to be adjusted to properly integrate with your Flutter app)
      // runApp(MaterialApp(home: AlarmScreen(alarm: triggeredAlarm, audioPlayer: audioPlayer)));
    }
  }

  Future<void> cancelAlarm(int alarmId) async {
    await AndroidAlarmManager.cancel(alarmId);
  }

  Future<void> saveAlarms(List<AlarmInfo> alarms) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> alarmStrings =
        alarms.map((alarm) => jsonEncode(alarm.toJson())).toList();
    await prefs.setStringList('alarms', alarmStrings);
  }

  Future<List<AlarmInfo>> loadAlarms() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> alarmStrings = prefs.getStringList('alarms') ?? [];
    return alarmStrings
        .map((alarmString) => AlarmInfo.fromJson(jsonDecode(alarmString)))
        .toList();
  }

  String determineSound(List<Map<String, dynamic>> weatherData) {
    final rain = weatherData[0]['RN1'];
    final snow = weatherData[0]['T1H'];

    if (rain != null && double.tryParse(rain)! > 0) {
      return 'sca_kr024_v01_w009_wv1.ogg'; // Rainy day sound file
    } else if (snow != null && double.tryParse(snow)! < 0) {
      return 'sca_kr024_v01_w001_wv1.ogg'; // Snowy day
    } else {
      return 'sca_kr024_v01_w014_wv1.ogg'; // Default weather
    }
  }

  Future<void> playSound(String soundFileName) async {
    try {
      await audioPlayer.play(AssetSource('lib/assets/sounds/$soundFileName'));
    } catch (e) {
      print('Error playing sound: $e');
    }
  }
}
