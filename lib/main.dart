import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_voice_alarm/alarm_info.dart';
import 'package:flutter_voice_alarm/alarm_manager.dart';
import 'package:geolocator/geolocator.dart';
import 'weather_service.dart';
import 'vworld_address.dart';

Future<void> main() async {
  await dotenv.load();
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
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
  int nx = 0;
  int ny = 0;
  String _address = 'Loading address...';

  @override
  void initState() {
    super.initState();
    fetchWeather();
    loadAlarms();
    _getAddress();
  }

  void loadAlarms() async {
    AlarmManager alarmManager = AlarmManager(weatherService);
    alarms = await alarmManager.loadAlarms();
    setState(() {});
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

  final TimeOfDay _selectedTime = TimeOfDay.now();
  final DateTime _selectedDate = DateTime.now();

  void processWeatherData(List<Map<String, dynamic>> weatherData) {
    Map<String, Map<String, dynamic>> tempData = {};

    for (var data in weatherData) {
      tempData[data['category']] = data;
    }

    var vecValue = tempData['VEC'] != null
        ? double.tryParse(tempData['VEC']!['fcstValue'].toString())
        : null;
    latestWeatherData = {
      'temperature': tempData.containsKey('TMP')
          ? '온도: ${tempData['TMP']?['fcstValue']}°C'
          : '온도: 정보 없음',
      'skyStatus': weatherService.getSkyStatus(tempData['SKY']?['fcstValue']),
      'humidity': tempData.containsKey('REH')
          ? '습도: ${tempData['REH']?['fcstValue']}%'
          : '습도: 정보 없음',
      'windDirection': getWindDirection(vecValue),
      'windDirectionValue': vecValue, // 각도 저장
      'windSpeed': tempData.containsKey('WSD')
          ? '풍속: ${tempData['WSD']?['fcstValue']}m/s'
          : '풍속: 정보 없음',
      'precipitationType': getPrecipitationType(tempData['PTY']?['fcstValue']),
    };
  }

  Widget buildWeatherIcon() {
    if (latestWeatherData.containsKey('windDirectionValue')) {
      return RotatedBox(
        quarterTurns: getWindDirectionQuarterTurns(
            latestWeatherData['windDirectionValue']),
        child: const Icon(Icons.navigation),
      );
    } else {
      return const Icon(Icons.cloud);
    }
  }

  String getWindDirection(double? vecValue) {
    if (vecValue == null) {
      return '풍향: 정보 없음';
    }
    if (vecValue >= 337.5 || vecValue < 22.5) {
      return '풍향: 북';
    } else if (vecValue >= 22.5 && vecValue < 67.5) {
      return '풍향: 북동';
    } else if (vecValue >= 67.5 && vecValue < 112.5) {
      return '풍향: 동';
    } else if (vecValue >= 112.5 && vecValue < 157.5) {
      return '풍향: 남동';
    } else if (vecValue >= 157.5 && vecValue < 202.5) {
      return '풍향: 남';
    } else if (vecValue >= 202.5 && vecValue < 247.5) {
      return '풍향: 남서';
    } else if (vecValue >= 247.5 && vecValue < 292.5) {
      return '풍향: 서';
    } else if (vecValue >= 292.5 && vecValue < 337.5) {
      return '풍향: 북서';
    } else {
      return '풍향: 정보 없음';
    }
  }

  int getWindDirectionQuarterTurns(double? vecValue) {
    if (vecValue == null) {
      return 0;
    }
    if (vecValue >= 337.5 || vecValue < 22.5) {
      return 0;
    } else if (vecValue >= 22.5 && vecValue < 67.5) {
      return 1;
    } else if (vecValue >= 67.5 && vecValue < 112.5) {
      return 2;
    } else if (vecValue >= 112.5 && vecValue < 157.5) {
      return 3;
    } else if (vecValue >= 157.5 && vecValue < 202.5) {
      return 4;
    } else if (vecValue >= 202.5 && vecValue < 247.5) {
      return 5;
    } else if (vecValue >= 247.5 && vecValue < 292.5) {
      return 6;
    } else if (vecValue >= 292.5 && vecValue < 337.5) {
      return 7;
    } else {
      return 0;
    }
  }

  String getPrecipitationType(String? pty) {
    switch (pty) {
      case '0':
        return '강수 형태: 없음';
      case '1':
        return '강수 형태: 비';
      case '2':
        return '강수 형태: 비/눈';
      case '3':
        return '강수 형태: 눈';
      case '5':
        return '강수 형태: 빗방울';
      case '6':
        return '강수 형태: 빗방울/눈날림';
      case '7':
        return '강수 형태: 눈날림';
      default:
        return '강수 형태: 정보 없음';
    }
  }

  void _showAddAlarmDialog() {
    TimeOfDay selectedTime = TimeOfDay.now();
    DateTime selectedDate = DateTime.now();
    List<bool> selectedDays = List.generate(7, (index) => false);
    TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('새 알람 추가'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: '알람 이름'),
                    ),
                    ListTile(
                      title: const Text('시간 선택'),
                      subtitle: Text(
                          '${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}'),
                      onTap: () async {
                        TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setState(() {
                            selectedTime = picked;
                          });
                        }
                      },
                    ),
                    ListTile(
                      title: const Text('날짜 선택'),
                      subtitle: Text(
                          '${selectedDate.year}-${selectedDate.month}-${selectedDate.day}'),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                    Wrap(
                      children: List<Widget>.generate(
                        7,
                        (int index) {
                          return ChoiceChip(
                            label: Text(
                                ['월', '화', '수', '목', '금', '토', '일'][index]),
                            selected: selectedDays[index],
                            onSelected: (bool selected) {
                              setState(
                                () {
                                  selectedDays[index] = selected;
                                },
                              );
                            },
                          );
                        },
                      ).toList(),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('취소'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('저장'),
                  onPressed: () {
                    Map<String, bool> repeatDays = {
                      "월": selectedDays[0],
                      "화": selectedDays[1],
                      "수": selectedDays[2],
                      "목": selectedDays[3],
                      "금": selectedDays[4],
                      "토": selectedDays[5],
                      "일": selectedDays[6],
                    };
                    setState(() {
                      alarms.add(
                        AlarmInfo(
                          id: alarms.length,
                          time: selectedTime,
                          date: selectedDate,
                          repeatDays: repeatDays,
                          name: nameController.text,
                          nx: nx,
                          ny: ny,
                        ),
                      );
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteAlarm(int id) {
    setState(() {
      alarms.removeWhere((alarm) => alarm.id == id);
    });
  }

  Future<void> _refreshWeather() async {
    await fetchWeather();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Information'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshWeather,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshWeather,
        child: ListView(
          children: [
            ListTile(
              leading: buildWeatherIcon(),
              title: Text(latestWeatherData['skyStatus'] ?? '정보 없음'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(latestWeatherData['temperature'] ?? '온도: 정보 없음'),
                  Text(latestWeatherData['humidity'] ?? '습도: 정보 없음'),
                  Text(latestWeatherData['windDirection'] ?? '풍향: 정보 없음'),
                  Text(latestWeatherData['windSpeed'] ?? '풍속: 정보 없음'),
                  Text(
                      latestWeatherData['precipitationType'] ?? '강수 형태: 정보 없음'),
                ],
              ),
            ),
            ListTile(
              title: Text(_address),
            ),
            ListTile(
              title: const Text('설정된 알람'),
              subtitle: Column(
                children: alarms
                    .map((alarm) => ListTile(
                          title: Text(alarm.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(alarm.getTimeString()),
                              Wrap(
                                spacing: 4.0,
                                children: alarm.repeatDays.keys.map((day) {
                                  return Text(
                                    day,
                                    style: TextStyle(
                                      color: (day == '토' || day == '일')
                                          ? Colors.red
                                          : Colors.black,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: alarm.isEnabled,
                                onChanged: (value) {
                                  setState(() {
                                    alarm.isEnabled = value;
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  _deleteAlarm(alarm.id);
                                },
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAlarmDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _getAddress() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    var data = await VWorldAddressService.fetchAddress(
        position.latitude, position.longitude);
    setState(() {
      _address = data['address'];
    });
  }
}
