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
      alarm.sound = determineSound(weatherData as Map<String, String?>);
      await playSound(alarm.sound);
    } catch (e) {
      // print('Error checking alarm: $e');
      // Optionally set a default sound if weather data fetch fails.
      await playSound('default_sound.mp3');
    }
  }

  String determineSound(Map<String, String?> weatherData) {
    final rain = weatherData['rain'];
    final snow = weatherData['snow'];
    final tempString = weatherData['temp'];

    if (rain == '1') {
      return 'sca_kr024_v01_w009_wv1.ogg'; // 비 오는 날의 사운드 파일
    } else if (snow == '1') {
      return 'sca_kr024_v01_w001_wv1.ogg'; // 눈 오는 날
    } else {
      double temp = double.tryParse(tempString ?? '0') ?? 0.0;
      if (temp < 0) {
        return 'sca_kr024_v01_w002_wv1.ogg'; // 추운 날
      }
    }
    return 'sca_kr024_v01_w014_wv1.ogg'; // 일반적인 날씨
  }

  Future<void> playSound(String soundFileName) async {
    try {
      await audioPlayer.play(AssetSource('lib/assets/sounds/$soundFileName'));
    } catch (e) {
      // print('Error playing sound: $e');
    }
  }
}
