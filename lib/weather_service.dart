import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String baseUrl =
      "https://apihub.kma.go.kr/api/typ02/openApi/VilageFcstInfoService_2.0/getVilageFcst";
  final String apiKey = "WaioH0gCRdioqB9IAmXYkg";

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
}
