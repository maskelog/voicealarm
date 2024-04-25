import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_voice_alarm/alarm_info.dart';
import 'package:flutter_voice_alarm/weather_service.dart';

class AlarmManager {
  final WeatherService weatherService;
  final AudioPlayer audioPlayer = AudioPlayer();

  AlarmManager(this.weatherService);

  Future<void> checkAlarm(AlarmInfo alarm) async {
    if (!alarm.isEnabled) return;

    try {
      var weatherData =
          await weatherService.getWeather(alarm.time, alarm.nx, alarm.ny);
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

  String determineSound(Map<String, String?> weatherData) {
    final rain = weatherData['RN1'];
    final snow = weatherData['T1H'];

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
