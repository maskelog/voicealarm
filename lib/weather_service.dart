import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherService {
  final String serviceKey;

  WeatherService(String apiKey)
      : serviceKey = dotenv.env['WEATHER_API_KEY'] ?? '';

  Future<String> getWeather(DateTime time) async {
    String formattedDate = DateFormat('yyyyMMdd').format(time);
    String formattedTime = DateFormat('HHmm').format(time);
    formattedTime =
        '${(int.parse(formattedTime.substring(0, 2)) ~/ 3 * 3).toString().padLeft(2, '0')}00';

    var url = Uri.parse(
            'http://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getVilageFcst')
        .replace(queryParameters: {
      'serviceKey': serviceKey,
      'pageNo': '1',
      'numOfRows': '100', // 예측 데이터 수를 충분히 가져옴
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
      return processWeatherData(items);
    } else {
      throw Exception(
          'Failed to fetch weather data: HTTP ${response.statusCode}');
    }
  }

  String processWeatherData(List<dynamic> items) {
    Map<String, Map<String, dynamic>> weatherInfo = {};
    for (var item in items) {
      String timeKey = item['fcstDate'] + item['fcstTime'];
      if (!weatherInfo.containsKey(timeKey)) {
        weatherInfo[timeKey] = {};
      }
      weatherInfo[timeKey]?[item['category']] = item['fcstValue'];
    }

    return formatWeatherData(weatherInfo);
  }

  String formatWeatherData(Map<String, Map<String, dynamic>> weatherData) {
    var result = StringBuffer();
    weatherData.forEach((time, data) {
      var dateTime = DateTime.parse(time);
      var formattedTime = DateFormat('yyyy년 MM월 dd일 HH시 mm분').format(dateTime);
      var sky = data['SKY'] != null ? skyCode[data['SKY']] : "데이터 없음";
      var pty = data['PTY'] != null ? ptyCode[data['PTY']] : "강수 없음";
      var temp = data['T1H']?.toString() ?? "데이터 없음";
      var windDir = data['VEC'] != null ? degToDir(data['VEC']) : "데이터 없음";
      var windSpeed = data['WSD']?.toString() ?? "데이터 없음";
      result.writeln(
          '$formattedTime: 하늘 상태: $sky, 강수 형태: $pty, 기온: $temp°C, 풍향: $windDir, 풍속: $windSpeed m/s');
    });
    return result.toString();
  }

  Map<int, String> skyCode = {1: '맑음', 3: '구름 많음', 4: '흐림'};
  Map<int, String> ptyCode = {
    0: '강수 없음',
    1: '비',
    2: '비/눈',
    3: '눈',
    5: '빗방울',
    6: '진눈깨비',
    7: '눈날림'
  };

  String degToDir(double deg) {
    Map<double, String> degCode = {
      0: 'N',
      360: 'N',
      180: 'S',
      270: 'W',
      90: 'E',
      22.5: 'NNE',
      45: 'NE',
      67.5: 'ENE',
      112.5: 'ESE',
      135: 'SE',
      157.5: 'SSE',
      202.5: 'SSW',
      225: 'SW',
      247.5: 'WSW',
      292.5: 'WNW',
      315: 'NW',
      337.5: 'NNW'
    };
    return degCode.entries
        .reduce((a, b) => (deg - a.key).abs() < (deg - b.key).abs() ? a : b)
        .value;
  }

  getWeatherData(String formattedDate, String formattedTime, String string,
      String string2) {}
}
