import 'package:flutter/material.dart';
import 'package:flutter_alarm_clock/services/vworld_address_service.dart';
import 'package:flutter_alarm_clock/services/weather_service.dart';
import 'package:flutter_alarm_clock/utils/location_helper.dart';
import 'package:geolocator/geolocator.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  WeatherScreenState createState() => WeatherScreenState();
}

class WeatherScreenState extends State<WeatherScreen> {
  WeatherService weatherService = WeatherService();
  Map<String, dynamic> latestWeatherData = {};
  String weatherDataMessage = "날씨 정보를 불러오는 중...";
  final TimeOfDay _selectedTime = TimeOfDay.now();
  final DateTime _selectedDate = DateTime.now();
  String _address = '주소를 불러오는 중...';
  String _error = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchWeather();
      getPositionAndAddress();
    });
  }

  Future<void> fetchWeather() async {
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
        print('Error fetching weather data: $e');
      });
    }
  }

  void processWeatherData(List<Map<String, dynamic>> weatherData) {
    Map<String, Map<String, dynamic>> tempData = {};

    for (var data in weatherData) {
      tempData[data['category']] = data;
    }

    var vecValue = tempData['VEC'] != null
        ? double.tryParse(tempData['VEC']?['fcstValue']?.toString() ?? '')
        : null;

    print('Processed Weather Data: $tempData');

    latestWeatherData = {
      'temperature':
          tempData.containsKey('TMP') && tempData['TMP']?['fcstValue'] != null
              ? '${tempData['TMP']?['fcstValue']}℃'
              : '정보 없음',
      'skyStatus':
          tempData.containsKey('SKY') && tempData['SKY']?['fcstValue'] != null
              ? weatherService
                  .getSkyStatus(tempData['SKY']?['fcstValue']?.toString() ?? '')
              : '정보 없음',
      'humidity':
          tempData.containsKey('REH') && tempData['REH']?['fcstValue'] != null
              ? '습도 ${tempData['REH']?['fcstValue']}%'
              : '습도 정보 없음',
      'windDirection': getWindDirection(vecValue),
      'windDirectionValue': vecValue,
      'windSpeed':
          tempData.containsKey('WSD') && tempData['WSD']?['fcstValue'] != null
              ? '${tempData['WSD']?['fcstValue']} m/s'
              : '정보 없음',
      'precipitationType':
          tempData.containsKey('PTY') && tempData['PTY']?['fcstValue'] != null
              ? getPrecipitationType(
                  tempData['PTY']?['fcstValue']?.toString() ?? '')
              : '정보 없음',
    };
  }

  Future<void> getPositionAndAddress() async {
    setState(() {
      _error = '';
    });

    try {
      Position? position = await LocationHelper.determinePosition();
      if (position == null) {
        setState(() {
          _address = '위치 정보를 가져오는데 실패했습니다.';
        });
        return;
      }

      String address = await VWorldAddressService.fetchAddress(
          position.latitude, position.longitude);
      setState(() {
        _address = address;
      });
    } catch (e) {
      setState(() {
        _address = '주소를 가져오는데 실패했습니다: $e';
        _error = e.toString();
      });
    }
  }

  String getWindDirection(double? windDirectionValue) {
    if (windDirectionValue == null) {
      return '정보 없음';
    }

    List<String> directions = [
      '북',
      '북북동',
      '북동',
      '동북동',
      '동',
      '동남동',
      '남동',
      '남남동',
      '남',
      '남남서',
      '남서',
      '서남서',
      '서',
      '서북서',
      '북서',
      '북북서',
    ];

    int index = ((windDirectionValue + 11.25) % 360 ~/ 22.5).toInt();
    return directions[index];
  }

  double getWindDirectionAngle(double? windDirectionValue) {
    if (windDirectionValue == null) {
      return 0.0;
    }
    return windDirectionValue * (3.1415926535897932 / 180);
  }

  String getPrecipitationType(dynamic precipitationValue) {
    if (precipitationValue == null) {
      return '강수: 정보 없음';
    }
    switch (precipitationValue.toString()) {
      case '0':
        return '강수 없음';
      case '1':
        return '강수 비';
      case '2':
        return '강수 비/눈';
      case '3':
        return '강수 눈';
      case '4':
        return '강수 소나기';
      default:
        return '강수 정보 없음';
    }
  }

  IconData getWeatherIcon(String skyStatus, String precipitationType) {
    if (precipitationType != '강수 없음') {
      switch (precipitationType) {
        case '강수 비':
          return Icons.grain;
        case '강수 비/눈':
          return Icons.ac_unit;
        case '강수 눈':
          return Icons.ac_unit;
        case '강수 소나기':
          return Icons.grain;
        default:
          return Icons.help;
      }
    } else {
      switch (skyStatus) {
        case '맑음':
          return Icons.wb_sunny;
        case '구름조금':
          return Icons.cloud_queue;
        case '구름많음':
          return Icons.cloud;
        case '흐림':
          return Icons.cloud_queue;
        default:
          return Icons.help;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.33,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _address,
                style: const TextStyle(fontSize: 18.0),
              ),
            ),
            if (latestWeatherData.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          latestWeatherData['temperature'],
                          style: const TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Icon(
                          getWeatherIcon(latestWeatherData['skyStatus'],
                              latestWeatherData['precipitationType']),
                          size: 40.0,
                          color: Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10.0),
                    Text(
                      latestWeatherData['skyStatus'],
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    const SizedBox(height: 10.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('바람'),
                        const SizedBox(width: 8.0),
                        if (latestWeatherData['windDirectionValue'] != null)
                          Transform.rotate(
                            angle: getWindDirectionAngle(
                                latestWeatherData['windDirectionValue']),
                            child: const Icon(Icons.navigation, size: 24.0),
                          ),
                        const SizedBox(width: 8.0),
                        Text(
                          '${latestWeatherData['windDirection']} ${latestWeatherData['windSpeed']}',
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      latestWeatherData['humidity'],
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      latestWeatherData['precipitationType'],
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  weatherDataMessage,
                  style: const TextStyle(fontSize: 18.0),
                ),
              ),
            if (_error.isNotEmpty)
              Text(
                _error,
                style: const TextStyle(color: Colors.red),
              ),
            Align(
              alignment: Alignment.bottomRight,
              child: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  fetchWeather();
                  getPositionAndAddress();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
