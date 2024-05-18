import 'package:flutter/material.dart';
import '../services/weather_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  WeatherScreenState createState() => WeatherScreenState();
}

class WeatherScreenState extends State<WeatherScreen> {
  WeatherService weatherService = WeatherService();
  Map<String, dynamic> latestWeatherData = {};
  String weatherDataMessage = "날씨 정보를 불러오는 중...";
  final TimeOfDay _selectedTime = TimeOfDay.now();
  final DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  fetchWeather() async {
    try {
      var data =
          await weatherService.fetchWeatherData(_selectedTime, _selectedDate);
      processWeatherData(data);
      setState(() {
        weatherDataMessage = "";
      });
    } catch (e) {
      setState(() {
        weatherDataMessage = "날씨 정보를 불러오는데 실패했습니다: $e";
      });
    }
  }

  void processWeatherData(List<Map<String, dynamic>> weatherData) {
    Map<String, Map<String, dynamic>> tempData = {};

    for (var data in weatherData) {
      tempData[data['category']] = data;
    }

    var vecValue = tempData['VEC'] != null
        ? double.tryParse(tempData['VEC']!['fcstValue'].toString())
        : null;

    print('Processed Weather Data: $tempData');

    latestWeatherData = {
      'temperature': tempData.containsKey('TMP')
          ? '온도: ${tempData['TMP']?['fcstValue']}°C'
          : '온도: 정보 없음',
      'skyStatus': weatherService.getSkyStatus(tempData['SKY']?['fcstValue']),
      'humidity': tempData.containsKey('REH')
          ? '습도: ${tempData['REH']?['fcstValue']}%'
          : '습도: 정보 없음',
      'windDirection': getWindDirection(vecValue),
      'windDirectionValue': vecValue,
      'windSpeed': tempData.containsKey('WSD')
          ? '풍속: ${tempData['WSD']?['fcstValue']}m/s'
          : '풍속: 정보 없음',
      'precipitationType': getPrecipitationType(tempData['PTY']?['fcstValue']),
    };
  }

  String getWindDirection(double? vecValue) {
    if (vecValue == null) {
      return '풍향: 정보 없음';
    }
    if (vecValue >= 337.5 || vecValue < 22.5) {
      return '풍향: 북';
    } else if (vecValue >= 22.5 && vecValue < 67.5) {
      return '풍향: 북동';
    } else if (vecValue >= 67.5 && vecValue < 112.5) {
      return '풍향: 동';
    } else if (vecValue >= 112.5 && vecValue < 157.5) {
      return '풍향: 남동';
    } else if (vecValue >= 157.5 && vecValue < 202.5) {
      return '풍향: 남';
    } else if (vecValue >= 202.5 && vecValue < 247.5) {
      return '풍향: 남서';
    } else if (vecValue >= 247.5 && vecValue < 292.5) {
      return '풍향: 서';
    } else if (vecValue >= 292.5 && vecValue < 337.5) {
      return '풍향: 북서';
    } else {
      return '풍향: 정보 없음';
    }
  }

  String getPrecipitationType(String? pty) {
    switch (pty) {
      case '0':
        return '강수형태: 없음';
      case '1':
        return '강수형태: 비';
      case '2':
        return '강수형태: 비/눈';
      case '3':
        return '강수형태: 눈';
      case '4':
        return '강수형태: 소나기';
      default:
        return '강수형태: 정보 없음';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (weatherDataMessage.isNotEmpty)
          Text(weatherDataMessage)
        else
          Column(
            children: [
              Text(latestWeatherData['temperature'] ?? '온도: 정보 없음'),
              Text(latestWeatherData['skyStatus'] ?? '하늘 상태: 정보 없음'),
              Text(latestWeatherData['humidity'] ?? '습도: 정보 없음'),
              Text(latestWeatherData['windDirection'] ?? '풍향: 정보 없음'),
              Text(latestWeatherData['windSpeed'] ?? '풍속: 정보 없음'),
              Text(latestWeatherData['precipitationType'] ?? '강수형태: 정보 없음'),
            ],
          ),
      ],
    );
  }
}
