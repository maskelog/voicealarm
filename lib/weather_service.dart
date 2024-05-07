import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  final String baseUrl =
      "https://apihub.kma.go.kr/api/typ02/openApi/VilageFcstInfoService_2.0/getVilageFcst";
  final String apiKey = dotenv.env['APIHUB']!;

  int weatherNx = 0;
  int weatherNy = 0;

  Future<Map<String, dynamic>> fetchWeather(
      int nx, int ny, String baseDate, String baseTime) async {
    final response = await http.get(
      Uri.parse(
          "$baseUrl?pageNo=1&numOfRows=100&dataType=JSON&base_date=$baseDate&base_time=$baseTime&nx=$nx&ny=$ny&authKey=$apiKey"),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // API 응답에서 필요한 데이터만 추출
      if (data['response']['header']['resultCode'] == '00') {
        return data['response']['body']['items'];
      } else {
        throw Exception('Failed to load weather data');
      }
    } else {
      throw Exception('Failed to connect to the Weather API');
    }
  }

  Future<List<Map<String, dynamic>>> fetchWeatherData(
      TimeOfDay selectedTime, DateTime selectedDate) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      var availableHours = [5, 8, 11, 14, 17, 20, 23];
      var currentHour = selectedTime.hour;

      // 선택한 시간에 가장 가까운 가능한 시간을 찾음
      var closestHour = availableHours.reduce(
          (a, b) => (b - currentHour).abs() < (a - currentHour).abs() ? b : a);

      // 선택한 시간이 05시 이전이면 전날의 23시 데이터를 가져옴
      if (closestHour < 5) {
        selectedDate = selectedDate.subtract(const Duration(days: 1));
        closestHour = 23;
      }

      // API 호출
      var response = await http.get(
        Uri.parse(
          'https://api.weather.com/v3/wx/forecast/daily/5day?apiKey=YOUR_API_KEY&geocode=${position.latitude},${position.longitude}&format=json&language=ko-KR&units=e',
        ),
      );

      // API 응답 처리
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        // baseTime과 fcstTime에 따른 데이터 필터링
        var filteredData = data['forecasts'].where((forecast) {
          var baseTime = int.parse(forecast['baseTime']);
          var fcstTime = int.parse(forecast['fcstTime']);
          return baseTime == closestHour && (baseTime != 23 || fcstTime <= 800);
        }).toList();

        return filteredData;
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      throw Exception('Failed to connect to the Weather API');
    }
  }

  String formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  String formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}${time.minute.toString().padLeft(2, '0')}';
  }

  String getSkyStatus(String fcstValue) {
    switch (fcstValue) {
      case '1':
        return '맑음';
      case '2':
        return '구름조금';
      case '3':
        return '구름많음';
      case '4':
        return '흐림';
      default:
        return '알 수 없음';
    }
  }
}
