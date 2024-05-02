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
    String rainfall = '강수량: 알 수 없음';
    String snowfall = '적설량: 알 수 없음';

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
                List<Widget> children = [];
                String skyStatus = '알 수 없음';
                String rainStatus = '';
                double? uuu, vvv, windSpeed;
                String? temperature, windDirection, humidity;
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
                  if (data['category'] == 'PTY') {
                    switch (data['fcstValue']) {
                      case '0':
                        rainStatus = '강수형태: 없음';
                        break;
                      case '1':
                        rainStatus = '강수형태: 비';
                        break;
                      case '2':
                        rainStatus = '강수형태: 비/눈';
                        break;
                      case '3':
                        rainStatus = '강수형태: 눈';
                        break;
                      default:
                        rainStatus = '강수형태: 알 수 없음';
                    }
                  }
                  if (data['category'] == 'SKY') {
                    switch (data['fcstValue']) {
                      case '1':
                        skyStatus = '하늘 상태: 맑음';
                        break;
                      case '3':
                        skyStatus = '하늘 상태: 구름많음';
                        break;
                      case '4':
                        skyStatus = '하늘 상태: 흐림';
                        break;
                      default:
                        skyStatus = '하늘 상태: 알 수 없음';
                    }
                  }
                  if (data['category'] == 'REH') {
                    humidity = '${data['fcstValue']}%';
                  }
                  if ('POP' == data['category']) {
                    rainStatus = '강수확률: ${data['fcstValue']}%';
                  }
                  if ('PCP' == data['category']) {
                    switch (data['fcstValue']) {
                      case '강수없음':
                        rainfall = '강수량: 없음';
                        break;
                      default:
                        rainfall = '강수량: ${data['fcstValue']}mm';
                    }
                  }
                  if ('SNO' == data['category']) {
                    switch (data['fcstValue']) {
                      case '적설없음':
                        snowfall = '적설량: 없음';
                        break;
                      default:
                        snowfall = '적설량: ${data['fcstValue']}cm';
                    }
                  }
                }

                children.add(Text(skyStatus));
                children.add(Text(temperature ?? '',
                    style: const TextStyle(fontSize: 24)));
                children.add(windIcon ?? const SizedBox.shrink());
                children.add(Text(
                    '풍향: $windDirection, 풍속: ${windSpeed?.toStringAsFixed(1)}m/s'));
                children.add(Text('습도: $humidity'));
                children.add(Text(rainStatus));
                if (rainfall.isNotEmpty == true && rainfall != '강수량: 없음') {
                  children.add(Text(rainfall));
                }
                if (snowfall.isNotEmpty == true && snowfall != '적설량: 없음') {
                  children.add(Text(snowfall));
                }
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
