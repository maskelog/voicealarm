import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_voice_alarm/alarm_info.dart';
import 'package:intl/intl.dart';
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
  Map<String, dynamic> latestWeatherData = {};
  String weatherDataMessage = "날씨 정보를 불러오는 중...";
  List<AlarmInfo> alarms = [];

  @override
  void initState() {
    super.initState();
    fetchWeather();
    loadAlarms();
  }

  void loadAlarms() {
    // 이 함수는 알람 데이터를 로드하는 로직을 구현해야 함
    // 예: alarms = await alarmStorage.getAlarms();
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
      tempData[data['category']] = data;
    }

    latestWeatherData = {
      'temperature': tempData.containsKey('TMP')
          ? '온도: ${tempData['TMP']!['fcstValue']}°C'
          : '온도: 정보 없음',
      'skyStatus': getSkyStatus(tempData['SKY']?['fcstValue']),
      'humidity': tempData.containsKey('REH')
          ? '습도: ${tempData['REH']!['fcstValue']}%'
          : '습도: 정보 없음',
      'windDirection': getWindDirection(tempData['VEC']?['fcstValue']),
      'windSpeed': tempData.containsKey('WSD')
          ? '풍속: ${tempData['WSD']!['fcstValue']}m/s'
          : '풍속: 정보 없음',
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
    ][(angle / 45).floor() % 8];
  }

  Widget getWindDirectionWidget(double? vec) {
    if (vec == null) return const Text('방향 정보 없음');
    return Transform.rotate(
      angle: -vec * math.pi / 180,
      child: const Icon(Icons.arrow_upward),
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
        title: const Text('보이스 알람'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () async {
              final DateTime? date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2050),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                });
                updateWeatherData();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.access_time),
            onPressed: () async {
              final TimeOfDay? time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (time != null) {
                setState(() {
                  _selectedTime = time;
                });
                updateWeatherData();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(weatherDataMessage),
                Text(latestWeatherData['temperature'] ?? '온도: 정보 없음'),
                Text(latestWeatherData['skyStatus'] ?? '하늘 상태: 정보 없음'),
                Text(latestWeatherData['humidity'] ?? '습도: 정보 없음'),
                Text(latestWeatherData['windDirection'] ?? '풍향: 정보 없음'),
                Text(latestWeatherData['windSpeed'] ?? '풍속: 정보 없음'),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: alarms.length,
              itemBuilder: (context, index) {
                final alarm = alarms[index];
                return ListTile(
                  title:
                      Text('알람: ${alarm.time.format(context)} - ${alarm.name}'),
                  subtitle: Text('Enabled: ${alarm.isEnabled}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => showEditAlarmDialog(alarm, index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddAlarmDialog,
        tooltip: 'Add Alarm',
        child: const Icon(Icons.add),
      ),
    );
  }

  void showEditAlarmDialog(AlarmInfo alarm, int index) {
    TextEditingController nameController =
        TextEditingController(text: alarm.name);
    TimeOfDay selectedTime = alarm.time;
    DateTime selectedDate = alarm.date;
    List<String> daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    // 기존 알람의 반복 요일 상태를 가져와서 복사합니다.
    List<bool> selectedDays =
        daysOfWeek.map((day) => alarm.repeatDays[day] ?? false).toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Edit Alarm'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: nameController,
                      decoration:
                          const InputDecoration(labelText: 'Alarm Name'),
                    ),
                    ListTile(
                      title: Text('Time: ${selectedTime.format(context)}'),
                      onTap: () async {
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (pickedTime != null) {
                          setStateDialog(() {
                            selectedTime = pickedTime;
                          });
                        }
                      },
                    ),
                    ListTile(
                      title: Text(
                          'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
                      onTap: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2050),
                        );
                        if (pickedDate != null) {
                          setStateDialog(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                    ),
                    Wrap(
                      spacing: 8.0,
                      children:
                          List<Widget>.generate(daysOfWeek.length, (int index) {
                        return ChoiceChip(
                          label: Text(daysOfWeek[index]),
                          selected: selectedDays[index],
                          onSelected: (bool selected) {
                            setStateDialog(() {
                              selectedDays[index] = selected;
                            });
                          },
                          selectedColor: Colors.blue,
                          backgroundColor: Colors.grey,
                          labelStyle: TextStyle(
                              color: selectedDays[index]
                                  ? Colors.white
                                  : Colors.black),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      alarms[index] = AlarmInfo(
                        time: selectedTime,
                        date: selectedDate,
                        repeatDays: Map.fromIterables(daysOfWeek, selectedDays),
                        isEnabled: alarm.isEnabled,
                        sound: alarm.sound,
                        name: nameController.text.trim(),
                        nx: alarm.nx,
                        ny: alarm.ny,
                      );
                    });
                  },
                  child: const Text('Save'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      alarms.removeAt(index);
                    });
                  },
                  child:
                      const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showAddAlarmDialog() {
    TextEditingController nameController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();
    DateTime selectedDate = DateTime.now();
    List<bool> selectedDays = List.generate(7, (_) => false); // 모든 요일 비활성화로 초기화

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Alarm'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Alarm Name'),
                ),
                ListTile(
                  title: Text('Time: ${selectedTime.format(context)}'),
                  onTap: () async {
                    final TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (pickedTime != null) {
                      selectedTime = pickedTime;
                    }
                  },
                ),
                ListTile(
                  title: Text('Date: ${selectedDate.toString()}'),
                  onTap: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2050),
                    );
                    if (pickedDate != null) {
                      selectedDate = pickedDate;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // 요일 배열
                List<String> daysOfWeek = [
                  "Mon",
                  "Tue",
                  "Wed",
                  "Thu",
                  "Fri",
                  "Sat",
                  "Sun"
                ];
                // List<bool>을 Map<String, bool>로 변환
                Map<String, bool> daysMap = {
                  for (int i = 0; i < daysOfWeek.length; i++)
                    daysOfWeek[i]: selectedDays[i]
                };

                setState(() {
                  // 알람 정보 객체를 생성하고 리스트에 추가합니다.
                  alarms.add(AlarmInfo(
                      time: selectedTime,
                      date: selectedDate,
                      repeatDays: daysMap,
                      isEnabled: true,
                      sound: 'default_sound.mp3',
                      name: nameController.text.trim(),
                      nx: 0, // 임시 좌표 값
                      ny: 0 // 임시 좌표 값
                      ));
                });
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                disabledForegroundColor:
                    Colors.grey.withOpacity(0.38).withOpacity(0.38),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
