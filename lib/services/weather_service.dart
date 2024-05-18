import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  final String baseUrl =
      "https://apihub.kma.go.kr/api/typ02/openApi/VilageFcstInfoService_2.0/getVilageFcst";
  final String apiKey;

  WeatherService() : apiKey = dotenv.env['APIHUB']! {
    if (apiKey.isEmpty) {
      throw Exception(
          "API key not found. Make sure to set APIHUB in .env file.");
    }
  }

  Future<Map<String, dynamic>> fetchWeather(
      int nx, int ny, String baseDate, String baseTime) async {
    final url = Uri.parse(
        "$baseUrl?pageNo=1&numOfRows=100&dataType=JSON&base_date=$baseDate&base_time=$baseTime&nx=$nx&ny=$ny&authKey=$apiKey");

    print("Request URL: $url");

    final response = await http.get(url);

    print("Response status: ${response.statusCode}");
    print("Response body: ${utf8.decode(response.bodyBytes)}");

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));

      if (data['response']['header']['resultCode'] == '00') {
        print('Response Data: $data');
        return data['response']['body']['items'];
      } else {
        throw Exception(
            'Failed to load weather data: ${data['response']['header']['resultMsg']}');
      }
    } else {
      throw Exception(
          'Failed to connect to the Weather API. Status: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchWeatherData(
      TimeOfDay selectedTime, DateTime selectedDate) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      var availableHours = [5, 8, 11, 14, 17, 20, 23];
      var currentHour = selectedTime.hour;

      var closestHour = availableHours.reduce(
          (a, b) => (b - currentHour).abs() < (a - currentHour).abs() ? b : a);

      // 0500시 이전이면 전날 2300시 baseTime을 사용
      if (selectedTime.hour < 5) {
        selectedDate = selectedDate.subtract(const Duration(days: 1));
        closestHour = 23;
      }

      var closestTime = TimeOfDay(hour: closestHour, minute: 0);

      // 소수점을 제거한 좌표 사용
      int nx = position.latitude.floor();
      int ny = position.longitude.floor();

      var weatherData = await fetchWeather(
        nx,
        ny,
        formatDate(selectedDate),
        formatTime(closestTime),
      );

      return List<Map<String, dynamic>>.from(
          weatherData['item'].map((item) => item as Map<String, dynamic>));
    } catch (e) {
      print('Detailed error: ${e.toString()}');
      return [];
    }
  }

  String formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  String formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}00';
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
