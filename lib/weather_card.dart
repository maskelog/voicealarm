import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherCard extends StatefulWidget {
  const WeatherCard({Key? key}) : super(key: key);

  @override
  WeatherCardState createState() => WeatherCardState();
}

class WeatherCardState extends State<WeatherCard> {
  final bool _isLoading = true;
  Map<String, dynamic> weatherData = {};

  @override
  void initState() {
    super.initState();
    getWeatherData();
  }

  Future<Map<String, dynamic>> getWeatherData() async {
    final String apiKey = dotenv.env['APIHUB']!;

    // 사용자의 현재 위치를 가져옵니다.
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    // 현재 날짜와 시간을 가져옵니다.
    DateTime now = DateTime.now();
    String baseDate =
        "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    String baseTime = "${now.hour.toString().padLeft(2, '0')}00";

    // API URL을 구성합니다.
    String url =
        "http://apis.data.go.kr/1360000/VilageFcstInfoService/getVilageFcst?serviceKey=$apiKey&numOfRows=10&pageNo=1&base_date=$baseDate&base_time=$baseTime&nx=${position.latitude}&ny=${position.longitude}&dataType=JSON";

    // API를 호출합니다.
    http.Response response = await http.get(Uri.parse(url));

    // 응답을 파싱합니다.
    Map<String, dynamic> weatherData = jsonDecode(response.body);

    return weatherData;
  }

  Future<DateTime?> selectDate(BuildContext context) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
    );
    return selectedDate;
  }

  Future<TimeOfDay?> selectTime(BuildContext context) async {
    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    return selectedTime;
  }

  Future<DateTime?> selectDateTime(BuildContext context) async {
    DateTime? selectedDate = await selectDate(context);
    if (selectedDate == null) return null;

    TimeOfDay? selectedTime = await selectTime(context);
    if (selectedTime == null) return null;

    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
  }

  void processWeatherData(List<dynamic> items) {
    String skyStatus = '';
    Icon? weatherIcon;
    String rainfall = '강수량: 없음';
    String snowfall = '적설량: 없음';
    double? uuu;
    double? vvv;
    double? windSpeed;
    String? windDirection;

    for (var item in items) {
      switch (item['category']) {
        case 'SKY':
          switch (item['fcstValue']) {
            case '1':
              skyStatus = '하늘 상태: 맑음';
              weatherIcon = const Icon(Icons.wb_sunny);
              break;
            case '2':
              skyStatus = '하늘 상태: 구름조금';
              weatherIcon = const Icon(Icons.cloud);
              break;
            case '3':
              skyStatus = '하늘 상태: 구름많음';
              weatherIcon = const Icon(Icons.cloud);
              break;
            case '4':
              skyStatus = '하늘 상태: 흐림';
              weatherIcon = const Icon(Icons.cloud_off);
              break;
            default:
              skyStatus = '하늘 상태: 알 수 없음';
              weatherIcon = const Icon(Icons.error);
          }
          break;
        case 'PCP':
          if (item['fcstValue'] != '0') {
            rainfall = '강수량: ${item['fcstValue']}mm';
          }
          break;
        case 'SNO':
          if (item['fcstValue'] != '0') {
            snowfall = '적설량: ${item['fcstValue']}cm';
          }
          break;
        case 'UUU':
          uuu = double.tryParse(item['fcstValue'] ?? '0');
          break;
        case 'VVV':
          vvv = double.tryParse(item['fcstValue'] ?? '0');
          break;
      }

      // 풍속 및 풍향 계산
      if (uuu != null && vvv != null) {
        windSpeed = sqrt(pow(uuu, 2) + pow(vvv, 2));
        double angle = atan2(vvv, uuu) * 180 / pi;
        if (angle < 0) angle += 360;
        windDirection = [
          '북풍',
          '북동풍',
          '동풍',
          '남동풍',
          '남풍',
          '남서풍',
          '서풍',
          '북서풍'
        ][(angle / 45).floor() % 8];
      }
    }

    // 간략화된 데이터 맵을 전체 데이터로 설정
    weatherData = {
      'skyStatus': skyStatus,
      'weatherIcon': weatherIcon,
      'rainfall': rainfall,
      'snowfall': snowfall,
      'windSpeed': windSpeed?.toStringAsFixed(2) ?? 'No data',
      'windDirection': windDirection ?? 'No data',
    };
  }

  Map<String, dynamic> getSkyStatus(String? skyCode) {
    switch (skyCode) {
      case '1':
        return {
          'status': '맑음',
          'icon': Icons.wb_sunny,
        };
      case '3':
        return {
          'status': '구름많음',
          'icon': Icons.cloud,
        };
      case '4':
        return {
          'status': '흐림',
          'icon': Icons.cloud_off,
        };
      default:
        return {
          'status': '알 수 없음',
          'icon': Icons.error,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    var skyStatus = getSkyStatus(weatherData['skyStatus']);
    var statusText = skyStatus['status'];
    var statusIcon = Icon(skyStatus['icon']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Information'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              DateTime? selectedDateTime = await selectDateTime(context);
              if (selectedDateTime != null) {}
            },
          ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Temperature: ${weatherData['temperature']}°C'),
                      Text('Humidity: ${weatherData['humidity']}%'),
                      Text('Wind Speed: ${weatherData['windSpeed']}m/s'),
                      ListTile(
                        leading: statusIcon,
                        title: Text('Sky Status: $statusText'),
                      ),
                      Text('Rainfall: ${weatherData['rainfall']}'),
                      Text('Snowfall: ${weatherData['snowfall']}'),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
