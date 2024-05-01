import 'dart:math';

import 'package:flutter/material.dart';
import 'weather_service.dart';

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
  WeatherService weatherService = WeatherService();
  List<Map<String, dynamic>> weatherData = [];
  String weatherDataMessage = "날씨 정보를 불러오는 중...";

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  fetchWeather() async {
    try {
      weatherData =
          await weatherService.fetchWeatherData(_selectedTime, _selectedDate);
      setState(() {
        weatherDataMessage = "";
      });
    } catch (e) {
      setState(() {
        weatherDataMessage = "날씨 정보를 불러오는데 실패했습니다: $e";
      });
    }
  }

  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime _selectedDate = DateTime.now();
  final List<Map<String, dynamic>> _selectedWeatherData = [];

  Future<void> _selectTime(BuildContext context) async {
    const TimeOfDay initialTime = TimeOfDay(hour: 5, minute: 0);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        if (picked.hour < 5) {
          _selectedTime = const TimeOfDay(hour: 23, minute: 0);
          _selectedDate = _selectedDate.subtract(const Duration(days: 1));
        } else {
          _selectedTime = picked;
        }
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020, 1),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      _selectedDate = picked;
      await updateWeatherData();
    }
  }

  Future<void> updateWeatherData() async {
    var data =
        await weatherService.fetchWeatherData(_selectedTime, _selectedDate);
    setState(() {
      _selectedWeatherData.clear();
      _selectedWeatherData.addAll(data);
    });
  }

  @override
  Widget build(BuildContext context) {
    // 날씨 데이터를 시간별로 그룹화
    var groupedWeatherData = <String, List<Map<String, dynamic>>>{};
    for (var item in weatherData) {
      if (!groupedWeatherData.containsKey(item['baseTime'])) {
        groupedWeatherData[item['baseTime']] = [];
      }
      groupedWeatherData[item['baseTime']]?.add(item);
    }

    String? lastBaseTime;

    return Scaffold(
      appBar: AppBar(
        title: const Text('날씨 정보'),
      ),
      body: Column(
        children: <Widget>[
          if (weatherDataMessage.isNotEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(weatherDataMessage),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Text(
                'Selected time: ${_selectedTime.format(context)}',
              ),
              ElevatedButton(
                onPressed: () async {
                  await _selectDate(context);
                  var data = await weatherService.fetchWeatherData(
                      _selectedTime, _selectedDate);
                  setState(() {
                    weatherData = data;
                  });
                },
                child: const Text('Select date'),
              ),
              ElevatedButton(
                onPressed: () => _selectTime(context),
                child: const Text('Select time'),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _selectedWeatherData.length,
              itemBuilder: (context, index) {
                String? lastBaseTime; // 이전 baseTime 값을 추적하는 변수

                List<Widget> children = [];
                String skyStatus = '알 수 없음'; // 초기값 할당
                String rainStatus = '';
                double? uuu, vvv, windSpeed;
                String? temperature, windDirection;
                Widget? windIcon;

                for (var data in _selectedWeatherData) {
                  if (data['category'] == 'UUU') {
                    uuu = double.parse(data['fcstValue']);
                  }

                  if (data['category'] == 'VVV') {
                    vvv = double.parse(data['fcstValue']);
                  }

                  if (uuu != null && vvv != null) {
                    windSpeed = sqrt(pow(uuu, 2) + pow(vvv, 2));
                    double angle = atan2(vvv, uuu) * 180 / pi;

                    windIcon = Transform.rotate(
                      angle: -angle * pi / 180, // 각도를 라디안으로 변환
                      child: const Icon(Icons.arrow_upward),
                    );

                    if (angle < 0) {
                      angle += 360;
                    }

                    if (angle >= 337.5 || angle < 22.5) {
                      windDirection = '북풍';
                    } else if (angle >= 22.5 && angle < 67.5) {
                      windDirection = '북동풍';
                    } else if (angle >= 67.5 && angle < 112.5) {
                      windDirection = '동풍';
                    } else if (angle >= 112.5 && angle < 157.5) {
                      windDirection = '남동풍';
                    } else if (angle >= 157.5 && angle < 202.5) {
                      windDirection = '남풍';
                    } else if (angle >= 202.5 && angle < 247.5) {
                      windDirection = '남서풍';
                    } else if (angle >= 247.5 && angle < 292.5) {
                      windDirection = '서풍';
                    } else if (angle >= 292.5 && angle < 337.5) {
                      windDirection = '북서풍';
                    }
                  }

                  if (data['category'] == 'TMP') {
                    temperature = '온도: ${data['fcstValue']}℃';
                  }
                }

                children.add(Text(temperature ?? '',
                    style: const TextStyle(fontSize: 24)));
                children.add(windIcon ?? const SizedBox.shrink());
                children.add(Text(
                    '풍향: $windDirection, 풍속: ${windSpeed?.toStringAsFixed(1)}m/s'));
                return Card(
                  child: ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
