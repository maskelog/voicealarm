import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherService {
  final String serviceKey = dotenv.env['WEATHER_API_KEY'] ?? '';

  Future<bool> willItRain(
      String baseDate, String baseTime, String nx, String ny) async {
    var url = Uri.parse(
            'http://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getVilageFcst')
        .replace(queryParameters: {
      'serviceKey': serviceKey,
      'pageNo': '1',
      'numOfRows': '10',
      'dataType': 'JSON',
      'base_date': baseDate,
      'base_time': baseTime,
      'nx': nx,
      'ny': ny
    });

    var response = await http.get(url);

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data['response']['header']['resultCode'] == "0000") {
        // API 호출이 성공적인 경우
        var items = data['response']['body']['items']['item'];
        return items.any((element) =>
            element['category'] == 'PTY' &&
            (element['obsrValue'] == '1' ||
                element['obsrValue'] == '2' ||
                element['obsrValue'] == '3')); // PTY=강수형태, 1=비, 2=비/눈, 3=눈
      } else {
        throw Exception(
            'Failed to fetch weather data: ${data['response']['header']['resultMsg']}');
      }
    } else {
      throw Exception(
          'Failed to connect to the weather service: Status code ${response.statusCode}');
    }
  }

  getWeather(DateTime time) {}
}
