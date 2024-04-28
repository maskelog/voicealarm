import 'package:flutter/material.dart';
import 'weather_service.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: WeatherScreen(),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  WeatherScreenState createState() => WeatherScreenState();
}

class WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _weatherService = WeatherService();
  List<Map<String, dynamic>> _weatherData = [];
  String _weatherDataMessage = "날씨 정보를 불러오는 중...";

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  String formatDate(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}";
  }

  String formatTime(TimeOfDay time) {
    return "${time.hour.toString().padLeft(2, '0')}${time.minute.toString().padLeft(2, '0')}";
  }

  _fetchWeather() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      var weatherData = await _weatherService.fetchWeather(
        position.latitude.toInt(),
        position.longitude.toInt(),
        formatDate(DateTime.now()),
        formatTime(TimeOfDay.now()),
      );
      setState(() {
        _weatherData = List<Map<String, dynamic>>.from(
            weatherData.values.expand((item) => item).toList());
        _weatherDataMessage = "";
      });
    } catch (e) {
      setState(() {
        _weatherDataMessage = "날씨 정보를 불러오는데 실패했습니다: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('날씨 정보'),
      ),
      body: _weatherDataMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(_weatherDataMessage),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _weatherData.length,
              itemBuilder: (context, index) {
                String skyStatus = '알 수 없음'; // 초기값 할당
                if (_weatherData[index]['category'] == 'SKY') {
                  switch (_weatherData[index]['fcstValue']) {
                    case '1':
                      skyStatus = '맑음';
                      break;
                    case '2':
                      skyStatus = '구름조금';
                      break;
                    case '3':
                      skyStatus = '구름많음';
                      break;
                    case '4':
                      skyStatus = '흐림';
                      break;
                  }
                }
                return ListTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('시간: ${_weatherData[index]['baseTime']}'),
                      if (_weatherData[index]['category'] == 'TMP')
                        Text('온도: ${_weatherData[index]['fcstValue']}℃'),
                      if (_weatherData[index]['category'] == 'TMX')
                        Text('최고기온: ${_weatherData[index]['fcstValue']}℃'),
                      if (_weatherData[index]['category'] == 'TMN')
                        Text('최저기온: ${_weatherData[index]['fcstValue']}℃'),
                      if (_weatherData[index]['category'] == 'UUU')
                        Text('동서바람성분: ${_weatherData[index]['fcstValue']}'),
                      if (_weatherData[index]['category'] == 'VVV')
                        Text('남북바람성분: ${_weatherData[index]['fcstValue']}'),
                      if (_weatherData[index]['category'] == 'VEC')
                        Text('풍향: ${_weatherData[index]['fcstValue']}'),
                      if (_weatherData[index]['category'] == 'WSD')
                        Text('풍속: ${_weatherData[index]['fcstValue']}'),
                      if (_weatherData[index]['category'] == 'SKY')
                        Text('하늘상태: $skyStatus'),
                      if (_weatherData[index]['category'] == 'PTY')
                        Text('강수형태: ${_weatherData[index]['fcstValue']}'),
                      if (_weatherData[index]['category'] == 'POP')
                        Text('강수유무: ${_weatherData[index]['fcstValue']}'),
                      if (_weatherData[index]['category'] == 'PCP')
                        Text('1시간 강수량: ${_weatherData[index]['fcstValue']}'),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
