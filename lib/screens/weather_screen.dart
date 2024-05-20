import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../services/vworld_address_service.dart';
import '../utils/location_helper.dart';
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
        ? double.tryParse(tempData['VEC']!['fcstValue'].toString())
        : null;

    print('Processed Weather Data: $tempData');

    latestWeatherData = {
      'temperature': tempData.containsKey('TMP')
          ? '온도: ${tempData['TMP']?['fcstValue']}°C'
          : '온도: 정보 없음',
      'skyStatus': weatherService.getSkyStatus(tempData['SKY']?['fcstValue']),
      'humidity': tempData.containsKey('REH')
          ? '습도: ${tempData['REH']?['fcstValue']}%'
          : '습도: 정보 없음',
      'windDirection': getWindDirection(vecValue),
      'windDirectionValue': vecValue,
      'windSpeed': tempData.containsKey('WSD')
          ? '풍속: ${tempData['WSD']?['fcstValue']}m/s'
          : '풍속: 정보 없음',
      'precipitationType': getPrecipitationType(tempData['PTY']?['fcstValue']),
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

  String? getWindDirection(double? windDirectionValue) {
    if (windDirectionValue == null) {
      return null;
    }

    if ((windDirectionValue >= 0 && windDirectionValue <= 22.5) ||
        (windDirectionValue > 337.5 && windDirectionValue <= 360)) {
      return '풍향: N (북)';
    } else if (windDirectionValue > 22.5 && windDirectionValue <= 67.5) {
      return '풍향: NE (북동)';
    } else if (windDirectionValue > 67.5 && windDirectionValue <= 112.5) {
      return '풍향: E (동)';
    } else if (windDirectionValue > 112.5 && windDirectionValue <= 157.5) {
      return '풍향: SE (남동)';
    } else if (windDirectionValue > 157.5 && windDirectionValue <= 202.5) {
      return '풍향: S (남)';
    } else if (windDirectionValue > 202.5 && windDirectionValue <= 247.5) {
      return '풍향: SW (남서)';
    } else if (windDirectionValue > 247.5 && windDirectionValue <= 292.5) {
      return '풍향: W (서)';
    } else if (windDirectionValue > 292.5 && windDirectionValue <= 337.5) {
      return '풍향: NW (북서)';
    }
    return null;
  }

  String getPrecipitationType(dynamic precipitationValue) {
    if (precipitationValue == null) {
      return '강수 형태: 정보 없음';
    }
    switch (precipitationValue.toString()) {
      case '0':
        return '강수 형태: 없음';
      case '1':
        return '강수 형태: 비';
      case '2':
        return '강수 형태: 비/눈';
      case '3':
        return '강수 형태: 눈';
      case '4':
        return '강수 형태: 소나기';
      default:
        return '강수 형태: 정보 없음';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _address,
              style: const TextStyle(fontSize: 18.0),
            ),
          ),
          latestWeatherData.isNotEmpty
              ? Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        latestWeatherData['temperature'],
                        style: const TextStyle(fontSize: 18.0),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        latestWeatherData['skyStatus'],
                        style: const TextStyle(fontSize: 18.0),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        latestWeatherData['humidity'],
                        style: const TextStyle(fontSize: 18.0),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        latestWeatherData['windDirection'] ?? '풍향: 정보 없음',
                        style: const TextStyle(fontSize: 18.0),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        latestWeatherData['windSpeed'],
                        style: const TextStyle(fontSize: 18.0),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        latestWeatherData['precipitationType'],
                        style: const TextStyle(fontSize: 18.0),
                      ),
                    ],
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    weatherDataMessage,
                    style: const TextStyle(fontSize: 18.0),
                  ),
                ),
          _error.isNotEmpty
              ? Text(
                  _error,
                  style: const TextStyle(color: Colors.red),
                )
              : Container(),
        ],
      ),
    );
  }
}
