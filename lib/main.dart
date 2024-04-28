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
      var now = DateTime.now();
      var roundedHour = (now.hour ~/ 3) * 3; // 가장 가까운 3시간 간격으로 시간을 반올림

      // 현재 시간이 05시 이전이면 전날의 23시 데이터를 가져옴
      if (roundedHour < 5) {
        now = now.subtract(const Duration(days: 1));
        roundedHour = 23;
      }

      var roundedTime = TimeOfDay(hour: roundedHour, minute: 0);
      var weatherData = await _weatherService.fetchWeather(
        position.latitude.toInt(),
        position.longitude.toInt(),
        formatDate(now),
        formatTime(roundedTime),
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

  _showDatePicker() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2021),
      lastDate: DateTime(2030),
    );
    if (selectedDate != null) {
      // Do something with the selected date
    }
  }

  _showTimePicker() async {
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (selectedTime != null) {
      // Do something with the selected time
    }
  }

  @override
  Widget build(BuildContext context) {
    // 날씨 데이터를 시간별로 그룹화
    var groupedWeatherData = <String, List<Map<String, dynamic>>>{};
    for (var item in _weatherData) {
      if (!groupedWeatherData.containsKey(item['baseTime'])) {
        groupedWeatherData[item['baseTime']] = [];
      }
      groupedWeatherData[item['baseTime']]?.add(item);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('날씨 정보'),
      ),
      body: _weatherDataMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(_weatherDataMessage),
                  ElevatedButton(
                    onPressed: _showDatePicker,
                    child: const Text('날짜 선택'),
                  ),
                  ElevatedButton(
                    onPressed: _showTimePicker,
                    child: const Text('시간 선택'),
                  ),
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
                        Text('풍속: ${_weatherData[index]['fcstValue']}m/s'),
                      if (_weatherData[index]['category'] == 'SKY')
                        Text('하늘상태: $skyStatus'),
                      if (_weatherData[index]['category'] == 'PTY')
                        Text('강수형태: ${_weatherData[index]['fcstValue']}'),
                      if (_weatherData[index]['category'] == 'POP')
                        Text('강수유무: ${_weatherData[index]['fcstValue']}%'),
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
