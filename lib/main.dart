import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_voice_alarm/alarm_page.dart';
import 'weather_service.dart';

Future main() async {
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WeatherScreen(),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  WeatherScreen({super.key});
  final List<Alarm> alarms = [];

  @override
  WeatherScreenState createState() => WeatherScreenState();
}

class WeatherScreenState extends State<WeatherScreen> {
  WeatherService weatherService = WeatherService();
  Map<String, dynamic> latestWeatherData = {};
  String weatherDataMessage = "날씨 정보를 불러오는 중...";
  List<Alarm> alarms = [];
  final List<bool> _selectedDays = [
    false,
    false,
    false,
    false,
    false,
    false,
    false
  ];
  final bool _isEnabled = true;
  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  fetchWeather() async {
    try {
      var data =
          await weatherService.fetchWeatherData(_selectedTime, _selectedDate);
      processWeatherData(data);
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

  void processWeatherData(List<Map<String, dynamic>> weatherData) {
    Map<String, Map<String, dynamic>> tempData = {};

    for (var data in weatherData) {
      if (!tempData.containsKey(data['category'])) {
        tempData[data['category']] = {};
      }
      tempData[data['category']] = data;
    }
    var vecData = tempData.containsKey('VEC') ? tempData['VEC'] : null;
    var windDirectionValue = vecData != null ? vecData['fcstValue'] : null;
    latestWeatherData = {
      'temperature': tempData.containsKey('TMP')
          ? '온도: ${tempData['TMP']?['fcstValue']}°C'
          : '온도: 정보 없음',
      'skyStatus': getSkyStatus(tempData['SKY']?['fcstValue']),
      'humidity': tempData.containsKey('REH')
          ? '습도: ${tempData['REH']?['fcstValue']}%'
          : '습도: 정보 없음',
      'windDirection': tempData.containsKey('VEC')
          ? getWindDirection(tempData['VEC']?['fcstValue'])
          : '방향 정보 없음',
      'windSpeed': tempData.containsKey('WSD')
          ? '풍속: ${tempData['WSD']?['fcstValue']}m/s'
          : '풍속: 정보 없음',
      'windDirectionValue': windDirectionValue,
      'precipitationType': getPrecipitationType(tempData['PTY']?['fcstValue']),
      'precipitationProbability': tempData.containsKey('POP')
          ? '${tempData['POP']?['fcstValue']}%'
          : '강수 확률: 정보 없음',
      'precipitationAmount': (tempData.containsKey('PCP') &&
              tempData['PCP']?['fcstValue'] != "강수없음")
          ? '${tempData['PCP']?['fcstValue']}mm'
          : null,
      'snowfallAmount': (tempData.containsKey('SNO') &&
              tempData['SNO']?['fcstValue'] != "적설없음")
          ? '${tempData['SNO']?['fcstValue']}cm'
          : null,
    };
  }

  String getSkyStatus(String? skyCode) {
    switch (skyCode) {
      case '1':
        return '맑음';
      case '3':
        return '구름 많음';
      case '4':
        return '흐림';
      default:
        return '알 수 없음';
    }
  }

  String getPrecipitationType(String? ptyCode) {
    switch (ptyCode) {
      case '0':
        return '없음';
      case '1':
        return '비';
      case '2':
        return '비/눈';
      case '3':
        return '눈/비';
      case '4':
        return '눈';
      default:
        return '알 수 없음';
    }
  }

  String getWindDirection(dynamic vec) {
    if (vec == null) return '방향 정보 없음';
    double? angle = (vec is String) ? double.tryParse(vec) : vec as double?;
    if (angle == null) return '방향 정보 없음';
    return [
      '북풍',
      '북동풍',
      '동풍',
      '남동풍',
      '남풍',
      '남서풍',
      '서풍',
      '북서풍'
    ][((angle + 22.5) % 360 / 45).floor() % 8];
  }

  Widget getWindDirectionWidget(dynamic vecValue) {
    if (vecValue == null) return const Text('방향 정보 없음');
    double? angle;
    if (vecValue is String) {
      angle = double.tryParse(vecValue);
    } else if (vecValue is int) {
      angle = vecValue.toDouble();
    } else if (vecValue is double) {
      angle = vecValue;
    }
    if (angle == null) return const Text('방향 정보 없음');

    // 화살표가 북쪽을 가리키도록 기본 설정하고, 각도만큼 회전
    return Transform.rotate(
      angle:
          (-angle + 90) * (math.pi / 180), // 각도를 라디안으로 변환, 90도 추가하여 북쪽 기준으로 조정
      child: const Icon(Icons.arrow_upward_sharp, size: 24, color: Colors.blue),
    );
  }

  bool isNumeric(String s) {
    return double.tryParse(s) != null;
  }

  updateWeatherData() {
    fetchWeather();
  }

  Widget getVECValueWidget() {
    var vec = latestWeatherData['windDirection'];
    if (vec == null) return const Text('VEC: 정보 없음');
    return Text('VEC: $vec');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('통합 날씨 정보'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2050),
              );
              if (date != null) {
                _selectedDate = date;
                updateWeatherData();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.access_time),
            onPressed: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (time != null) {
                _selectedTime = time;
                updateWeatherData();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.alarm),
            onPressed: () {
              setState(() {
                widget.alarms.add(
                  Alarm(
                      _selectedTime, _selectedDate, _selectedDays, _isEnabled),
                );
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('알람이 설정되었습니다.'),
                ),
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AlarmSettingPage(alarms: widget.alarms),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              weatherDataMessage.isNotEmpty
                  ? Text(weatherDataMessage)
                  : Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(latestWeatherData['temperature'] ??
                                '온도: 정보 없음'),
                            Text(latestWeatherData['skyStatus'] ??
                                '하늘 상태: 정보 없음'),
                            Text(latestWeatherData['humidity'] ?? '습도: 정보 없음'),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                    '${latestWeatherData['windDirection'] ?? '정보 없음'} ',
                                    style: const TextStyle(fontSize: 16)),
                                if (latestWeatherData['windDirectionValue'] !=
                                    null)
                                  getWindDirectionWidget(
                                      latestWeatherData['windDirectionValue']),
                              ],
                            ),
                            Text(latestWeatherData['windSpeed'] ?? '풍속: 정보 없음'),
                            if (latestWeatherData['precipitationAmount'] !=
                                null)
                              Text(
                                  '강수량: ${latestWeatherData['precipitationAmount']}'),
                            if (latestWeatherData['snowfallAmount'] != null)
                              Text(
                                  '적설: ${latestWeatherData['snowfallAmount']}'),
                            Text(
                                '강수 확률: ${latestWeatherData['precipitationProbability']}'),
                          ],
                        ),
                      ),
                    ),
              Expanded(
                child: ListView.builder(
                  itemCount: alarms.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title:
                          Text('알람 시간: ${alarms[index].time.format(context)}'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
