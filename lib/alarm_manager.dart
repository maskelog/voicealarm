import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_voice_alarm/alarm_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_voice_alarm/weather_service.dart';

class AlarmManager {
  final WeatherService weatherService;
  final AudioPlayer audioPlayer = AudioPlayer();

  AlarmManager(this.weatherService);

  Future<void> checkAlarm(AlarmInfo alarm) async {
    if (!alarm.isEnabled) return;

    try {
      var weatherData = await weatherService.fetchWeatherData(
        alarm.time,
        alarm.date,
      );
      alarm.sound = determineSound(weatherData);
      await playSound(alarm.sound);
    } catch (e) {
      // Print any errors that occur while checking the alarm
      if (kDebugMode) {
        print('Error checking alarm: $e');
      }
      await playSound('default_sound.mp3');
    }
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
      await audioPlayer.play('lib/assets/sounds/$soundFileName' as Source);
    } catch (e) {
      // Print any errors that occur while playing the sound
      if (kDebugMode) {
        print('Error playing sound: $e');
      }
    }
  }
}
