import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_voice_alarm/alarm_info.dart';
import 'package:flutter_voice_alarm/weather_service.dart';

class AlarmManager {
  final WeatherService weatherService;
  final AudioPlayer audioPlayer = AudioPlayer();

  AlarmManager(this.weatherService);

  Future<void> checkAlarm(AlarmInfo alarm) async {
    if (!alarm.isEnabled) return;

    try {
      var weatherData = await weatherService.getWeather(alarm.time);
      alarm.sound = determineSound(weatherData);
      await playSound(alarm.sound);
    } catch (e) {
      print('Error checking alarm: $e');
      await playSound('default_sound.mp3');
    }
  }

  String determineSound(Map<String, String?> weatherData) {
    final rain = weatherData['rain'];
    final snow = weatherData['snow'];
    final tempString = weatherData['temp'];

    if (rain == '1') {
      return 'sca_kr024_v01_w009_wv1.ogg'; // Rainy day sound file
    } else if (snow == '1') {
      return 'sca_kr024_v01_w001_wv1.ogg'; // Snowy day
    } else {
      double temp = double.tryParse(tempString ?? '0') ?? 0.0;
      if (temp < 0) {
        return 'sca_kr024_v01_w002_wv1.ogg'; // Cold day
      }
    }
    return 'sca_kr024_v01_w014_wv1.ogg'; // Default weather
  }

  Future<void> playSound(String soundFileName) async {
    try {
      await audioPlayer.play(AssetSource('lib/assets/sounds/$soundFileName'));
    } catch (e) {
      print('Error playing sound: $e');
    }
  }
}
