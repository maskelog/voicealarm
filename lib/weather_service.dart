import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class WeatherService {
  final String serviceKey;

  WeatherService() : serviceKey = dotenv.env['WEATHER_API_KEY'] ?? '';

  Future<Map<String, String?>> getWeather(DateTime time) async {
    String formattedDate = DateFormat('yyyyMMdd').format(time);
    String formattedTime =
        '${DateFormat('HHmm').format(time).substring(0, 2)}00';

    var url = Uri.parse(
            'http://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getVilageFcst')
        .replace(queryParameters: {
      'serviceKey': serviceKey,
      'pageNo': '1',
      'numOfRows': '10',
      'dataType': 'JSON',
      'base_date': formattedDate,
      'base_time': formattedTime,
      'nx': '55', // Example coordinates
      'ny': '127',
    });

    var response = await http.get(url);
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      var items = data['response']['body']['items']['item'] as List<dynamic>;
      return _processWeatherData(items);
    } else {
      throw Exception(
          'Failed to fetch weather data with status code: ${response.statusCode}');
    }
  }

  Map<String, String?> _processWeatherData(List<dynamic> items) {
    var resultMap = <String, String?>{};
    for (var item in items) {
      resultMap[item['category']] = item['fcstValue'].toString();
    }
    return resultMap;
  }

  getWeatherData(String formattedDate, String formattedTime, String string,
      String string2) {}
}
