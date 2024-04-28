import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'alarm_info.dart';
import 'alarm_manager.dart';
import 'weather_service.dart';
import 'geolocation.dart';

class AlarmPage extends StatefulWidget {
  const AlarmPage({super.key});

  @override
  AlarmPageState createState() => AlarmPageState();
}

class AlarmPageState extends State<AlarmPage> {
  List<AlarmInfo> alarms = [];
  late AlarmManager alarmManager;
  String weatherDescription = ""; // 날씨 설명을 저장하는 변수
  double temperature = 0.0; // 온도를 저장하는 변수
  String locationName = "Your Location"; // 위치 이름 저장

  late WeatherService weatherService; // 날씨 서비스 인스턴스 선언

  @override
  void initState() {
    super.initState();
    initializeWeatherService();
  }

  void initializeWeatherService() async {
    weatherService = WeatherService(); // WeatherService 인스턴스 생성
    alarmManager = AlarmManager(weatherService);
    await fetchWeather(); // 날씨 정보 가져오기
  }

  Future<void> fetchWeather() async {
    try {
      await _determinePosition();

      // formattedDate와 formattedTime 변수 사용하지 않음
      // String formattedDate = DateFormat('yyyyMMdd').format(DateTime.now());
      // String formattedTime = '0600';

      // getWeather 호출 시 필요한 모든 인자 전달
      var weatherData = await weatherService.getWeather(
          DateTime.now(), 0, 0); // 예시로 0 전달, 실제로 사용할 값으로 대체 필요

      if (weatherData.isNotEmpty) {
        // API 응답 내용 디버깅을 위한 출력
        if (kDebugMode) {
          print('Weather API Response: $weatherData');
        }

        setState(() {
          weatherDescription =
              "${weatherData['PTY'] ?? 'No weather data'}, ${weatherData['SKY'] ?? 'No condition data'}";
          temperature = double.tryParse(weatherData['T3H'] ?? '0') ?? 0.0;
          locationName = "Current Location";
        });
      } else {
        throw Exception('No weather data available');
      }
    } catch (e) {
      setState(() {
        weatherDescription = "Error fetching weather data: $e";
        temperature = 0.0;
        locationName = "Unknown Location";
      });
    }
  }

  Future<List<double>> getNxNyValues() async {
    try {
      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // 위치 권한이 거부된 경우 처리
          throw Exception('위치 정보 권한이 거부되었습니다.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // 위치 권한이 영구적으로 거부된 경우 처리
        throw Exception('위치 정보 권한이 영구적으로 거부되었습니다.');
      }

      // 현재 위치 가져오기
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // 현재 위치(위도, 경도)를 기상청 API 격자 좌표로 변환
      WeatherMapXY mapXY =
          changeLatLngToMap(position.longitude, position.latitude);

      return [mapXY.x.toDouble(), mapXY.y.toDouble()];
    } catch (e) {
      // 위치 정보 가져오기 실패 시 에러 처리
      if (kDebugMode) {
        print('Error getting location coordinates: $e');
      }
      throw Exception('위치 정보를 가져오는 데 실패했습니다.');
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  void _addOrUpdateAlarm(AlarmInfo alarm) {
    setState(() {
      int index = alarms.indexWhere((a) => a.time.isAtSameMomentAs(alarm.time));
      if (index != -1) {
        alarms[index] = alarm; // 기존 알람 업데이트
      } else {
        alarms.add(alarm); // 새 알람 추가
      }
    });
  }

  void _deleteAlarm(int index) {
    setState(() {
      alarms.removeAt(index); // 알람 삭제
    });
  }

  void _showAddAlarmDialog({AlarmInfo? initialAlarm}) async {
    TextEditingController nameController =
        TextEditingController(text: initialAlarm?.name ?? '');
    Map<String, bool> repeatDays = initialAlarm?.repeatDays ??
        {
          'Mon': false,
          'Tue': false,
          'Wed': false,
          'Thu': false,
          'Fri': false,
          'Sat': false,
          'Sun': false
        };
    TimeOfDay selectedTime = initialAlarm != null
        ? TimeOfDay(
            hour: initialAlarm.time.hour, minute: initialAlarm.time.minute)
        : TimeOfDay.now();

    List<double> nxNyValues;

    try {
      nxNyValues = await getNxNyValues();
    } catch (e) {
      // 위치 정보를 가져오는 데 실패한 경우 에러 메시지 출력 후 함수 종료
      if (kDebugMode) {
        print('Error getting nx and ny values: $e');
      }
      return;
    }

    // ignore: use_build_context_synchronously
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (pickedTime != null && pickedTime != selectedTime) {
      setState(() {
        selectedTime = pickedTime;
      });
    }

    // ignore: use_build_context_synchronously
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
                ElevatedButton(
                  onPressed: () async {
                    final TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (pickedTime != null && pickedTime != selectedTime) {
                      setState(() {
                        selectedTime = pickedTime;
                      });
                    }
                  },
                  child: Text('Select Time: ${selectedTime.format(context)}'),
                ),
                ...repeatDays.keys.map((day) {
                  bool isSelected = repeatDays[day] ?? false;
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: isSelected ? Colors.blue : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        repeatDays[day] = !isSelected;
                      });
                    },
                    child: Text(day),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                Navigator.of(context).pop();
                _addOrUpdateAlarm(AlarmInfo(
                  name: nameController.text.trim(),
                  time: DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                    selectedTime.hour,
                    selectedTime.minute,
                  ),
                  repeatDays: repeatDays,
                  isEnabled: initialAlarm?.isEnabled ?? true,
                  nx: nxNyValues[0].toInt(),
                  ny: nxNyValues[1].toInt(),
                ));
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedTime = DateFormat('h:mm a').format(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: const Text('보이스 알람'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              formattedTime,
              style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
            ),
          ),
          Text(
              "$locationName: $weatherDescription, Temp: ${temperature.toStringAsFixed(1)}°C"),
          Expanded(
            child: ListView.builder(
              itemCount: alarms.length,
              itemBuilder: (context, index) {
                final alarm = alarms[index];
                return ListTile(
                  title: Text(
                      '${alarm.name} ${alarm.time.hour.toString().padLeft(2, '0')}:${alarm.time.minute.toString().padLeft(2, '0')}'),
                  subtitle: Text(alarm.repeatDays.keys
                      .where((day) => alarm.repeatDays[day]!)
                      .join(', ')),
                  onTap: () => _showAddAlarmDialog(initialAlarm: alarm),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: alarm.isEnabled,
                        onChanged: (bool value) {
                          setState(() {
                            alarm.isEnabled = value;
                          });
                        },
                        activeColor: Colors.red,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteAlarm(index),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAlarmDialog,
        tooltip: 'Add Alarm',
        child: const Icon(Icons.add),
      ),
    );
  }
}
