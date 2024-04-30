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

                for (var data in _selectedWeatherData) {
                  if (lastBaseTime != data['baseTime']) {
                    lastBaseTime = data['baseTime'];
                    children.add(Text('시간: ${data['baseTime']}'));
                  }

                  String skyStatus = '알 수 없음'; // 초기값 할당
                  if (data['category'] == 'SKY') {
                    switch (data['fcstValue']) {
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

                  if (data['category'] == 'TMP') {
                    children.add(Text('온도: ${data['fcstValue']}℃'));
                  }
                  if (data['category'] == 'TMX') {
                    children.add(Text('최고기온: ${data['fcstValue']}℃'));
                  }
                  if (data['category'] == 'TMN') {
                    children.add(Text('최저기온: ${data['fcstValue']}℃'));
                  }
                  if (data['category'] == 'UUU') {
                    children.add(Text('동서바람성분: ${data['fcstValue']}'));
                  }
                  if (data['category'] == 'VVV') {
                    children.add(Text('남북바람성분: ${data['fcstValue']}'));
                  }
                  if (data['category'] == 'VEC') {
                    children.add(Text('풍향: ${data['fcstValue']}m/s'));
                  }
                  if (data['category'] == 'WSD') {
                    children.add(Text('풍속: ${data['fcstValue']}m/s'));
                  }
                  if (data['category'] == 'SKY') {
                    children.add(Text('하늘상태: $skyStatus'));
                  }
                  if (data['category'] == 'PTY') {
                    children.add(Text('강수형태: ${data['fcstValue']}'));
                  }
                  if (data['category'] == 'POP') {
                    children.add(Text('강수유무: ${data['fcstValue']}%'));
                  }
                  if (data['category'] == 'PCP') {
                    children.add(Text('1시간 강수량: ${data['fcstValue']}mm'));
                  }
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
