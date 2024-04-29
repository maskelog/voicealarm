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
                String skyStatus = '알 수 없음'; // 초기값 할당
                if (_selectedWeatherData[index]['category'] == 'SKY') {
                  switch (_selectedWeatherData[index]['fcstValue']) {
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
                return Card(
                  child: ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (weatherData.isNotEmpty) ...[
                          Text('시간: ${weatherData[index]['baseTime']}'),
                          if (weatherData[index]['category'] == 'TMP')
                            Text('온도: ${weatherData[index]['fcstValue']}℃'),
                          if (weatherData[index]['category'] == 'TMX')
                            Text('최고기온: ${weatherData[index]['fcstValue']}℃'),
                          if (weatherData[index]['category'] == 'TMN')
                            Text('최저기온: ${weatherData[index]['fcstValue']}℃'),
                          if (weatherData[index]['category'] == 'UUU')
                            Text('동서바람성분: ${weatherData[index]['fcstValue']}'),
                          if (weatherData[index]['category'] == 'VVV')
                            Text('남북바람성분: ${weatherData[index]['fcstValue']}'),
                          if (weatherData[index]['category'] == 'VEC')
                            Text('풍향: ${weatherData[index]['fcstValue']}'),
                          if (weatherData[index]['category'] == 'WSD')
                            Text('풍속: ${weatherData[index]['fcstValue']}m/s'),
                          if (weatherData[index]['category'] == 'SKY')
                            Text('하늘상태: $skyStatus'),
                          if (weatherData[index]['category'] == 'PTY')
                            Text('강수형태: ${weatherData[index]['fcstValue']}'),
                          if (weatherData[index]['category'] == 'POP')
                            Text('강수유무: ${weatherData[index]['fcstValue']}%'),
                          if (weatherData[index]['category'] == 'PCP')
                            Text('1시간 강수량: ${weatherData[index]['fcstValue']}'),
                        ],
                      ],
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
