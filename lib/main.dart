import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'weather_service.dart';

Future main() async {
  await dotenv.load();
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
            child: weatherCard(_selectedWeatherData),
          )
        ],
      ),
    );
  }

  ListView weatherCard(List<Map<String, dynamic>> selectedWeatherData) {
    return ListView.builder(
      itemCount: selectedWeatherData.length,
      itemBuilder: (context, index) {
        selectedWeatherData[index];
        double? uuu, vvv, windSpeed;
        String? temperature, windDirection, humidity, skyStatus = '알 수 없음';
        Icon? weatherIcon;
        String rainfall = '강수량: 없음';
        String snowfall = '적설량: 없음';

        // 데이터 분석 및 처리
        for (var data in selectedWeatherData) {
          switch (data['category']) {
            case 'UUU':
              uuu = double.tryParse(data['fcstValue'] ?? '0');
              break;
            case 'VVV':
              vvv = double.tryParse(data['fcstValue'] ?? '0');
              break;
            case 'TMP':
              temperature = '온도: ${data['fcstValue']}℃';
              break;
            case 'REH':
              humidity = '습도: ${data['fcstValue']}%';
              break;
            case 'SKY':
              switch (data['fcstValue']) {
                case '1':
                  skyStatus = '하늘 상태: 맑음';
                  weatherIcon = const Icon(Icons.wb_sunny);
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
              if (data['fcstValue'] != '강수없음') {
                rainfall = '강수량: ${data['fcstValue']}mm';
              }
              break;
            case 'SNO':
              if (data['fcstValue'] != '적설없음') {
                snowfall = '적설량: ${data['fcstValue']}cm';
              }
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

        // 위젯 리스트 구성
        List<Widget> children = [
          if (skyStatus != null && skyStatus.isNotEmpty) Text(skyStatus),
          if (weatherIcon != null) weatherIcon,
          if (temperature != null)
            Text(temperature, style: const TextStyle(fontSize: 24)),
          if (windDirection != null && windSpeed != null)
            Text('풍향: $windDirection, 풍속: ${windSpeed.toStringAsFixed(1)}m/s'),
          if (humidity != null) Text(humidity),
          if (rainfall != '강수량: 없음') Text(rainfall),
          if (snowfall != '적설량: 없음') Text(snowfall)
        ];

        return Card(
          child: ListTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        );
      },
    );
  }
}
