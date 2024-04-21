import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_voice_alarm/alarm_info.dart';
import 'package:flutter_voice_alarm/weather_service.dart';

class AlarmManager {
  final WeatherService weatherService;
  final AudioPlayer audioPlayer = AudioPlayer();

  AlarmManager(this.weatherService);

  Future<void> checkAlarm(AlarmInfo alarm) async {
    if (!alarm.isEnabled) return;

    var weatherData = await weatherService.getWeather(alarm.time);
    alarm.sound = determineSound(weatherData);

    playSound(alarm.sound);
  }

  String determineSound(Map<String, String?> weatherData) {
    final rain = weatherData['rain'];
    final snow = weatherData['snow'];
    final tempString = weatherData['temp'];

    if (rain != null && rain == '1') {
      return 'sca_kr024_v01_w009_wv1.ogg'; // 비 오는 날의 사운드 파일
    } else if (snow != null && snow == '1') {
      return 'sca_kr024_v01_w001_wv1.ogg'; // 눈 오는 날
    } else {
      double temp =
          tempString != null ? double.tryParse(tempString) ?? 0.0 : 0.0;
      if (temp < 0) {
        return 'sca_kr024_v01_w002_wv1.ogg'; // 바람 부는 날
      }
    }
    return 'sca_kr024_v01_w014_wv1.ogg'; // 날씨 좋은 날
  }

  void playSound(String soundFileName) async {
    await audioPlayer.play(AssetSource('lib/assets/sounds/$soundFileName'));
  }
}
