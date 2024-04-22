import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class WeatherService {
  final String serviceKey;

  WeatherService(this.serviceKey);

  // 날씨 데이터를 가져오는 메서드
  Future<Map<String, String?>> getWeather(DateTime time) async {
    String formattedDate = DateFormat('yyyyMMdd').format(time);
    String formattedTime = DateFormat('HHmm').format(time);

    // 시간은 API 요구 사항에 맞게 조정 (예: 0200, 0500, 0800, 등)
    formattedTime =
        '${(int.parse(formattedTime.substring(0, 2)) ~/ 3 * 3).toString().padLeft(2, '0')}00';

    var url = Uri.parse(
            'http://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getVilageFcst')
        .replace(queryParameters: {
      'serviceKey': serviceKey,
      'pageNo': '1',
      'numOfRows': '10',
      'dataType': 'JSON',
      'base_date': formattedDate,
      'base_time': formattedTime,
      'nx': '55', // 예시 격자 X 좌표
      'ny': '127' // 예시 격자 Y 좌표
    });

    var response = await http.get(url);
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      var items = data['response']['body']['items']['item'] as List;
      Map<String, String?> weatherData = {
        'rain': items.firstWhere((item) => item['category'] == 'PTY',
            orElse: () => {'obsrValue': null})['obsrValue'],
        'temp': items.firstWhere((item) => item['category'] == 'T1H',
            orElse: () => {'obsrValue': null})['obsrValue'],
        'snow': items.firstWhere((item) => item['category'] == 'PTY',
            orElse: () => {'obsrValue': null})['obsrValue'],
      };
      return weatherData;
    } else {
      throw Exception(
          'Failed to fetch weather data: HTTP ${response.statusCode}');
    }
  }

  getWeatherData(String s, String t, String string, String string2) {}
}
