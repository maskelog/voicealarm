import 'dart:math';
import 'package:geolocator/geolocator.dart';

class WeatherMapXY {
  final int x;
  final int y;
  WeatherMapXY(this.x, this.y);
}

class LamcParameter {
  double re; // 사용할 지구 반경 [km]
  double grid; // 격자 간격 [km]
  double slat1; // 표준 위도 [degree]
  double slat2; // 표준 위도 [degree]
  double olon; // 기준점의 경도 [degree]
  double olat; // 기준점의 위도 [degree]
  double xo; // 기준점의 X 좌표 [격자 거리]
  double yo; // 기준점의 Y 좌표 [격자 거리]

  LamcParameter({
    required this.re,
    required this.grid,
    required this.slat1,
    required this.slat2,
    required this.olon,
    required this.olat,
    required this.xo,
    required this.yo,
  });
}

// 위도와 경도를 격자 좌표로 변환
WeatherMapXY changeLatLngToMap(double longitude, double latitude) {
  const double piValue = pi;
  const double degRad = piValue / 180.0;

  LamcParameter map = LamcParameter(
    re: 6371.00877, // 지구 반경
    grid: 5.0, // 격자 간격
    slat1: 30.0, // 표준 위도 1
    slat2: 60.0, // 표준 위도 2
    olon: 126.0, // 기준점 경도
    olat: 38.0, // 기준점 위도
    xo: 210 / 5.0, // 기준점 X 좌표
    yo: 675 / 5.0, // 기준점 Y 좌표
  );

  double re = map.re / map.grid;
  double slat1 = map.slat1 * degRad;
  double slat2 = map.slat2 * degRad;
  double olon = map.olon * degRad;
  double olat = map.olat * degRad;

  double sn =
      tan(piValue * 0.25 + slat2 * 0.5) / tan(piValue * 0.25 + slat1 * 0.5);
  sn = log(cos(slat1) / cos(slat2)) / log(sn);
  double sf = tan(piValue * 0.25 + slat1 * 0.5);
  sf = pow(sf, sn) * cos(slat1) / sn;
  double ro = tan(piValue * 0.25 + olat * 0.5);
  ro = re * sf / pow(ro, sn);

  double ra = tan(piValue * 0.25 + latitude * degRad * 0.5);
  ra = re * sf / pow(ra, sn);
  double theta = longitude * degRad - olon;
  if (theta > piValue) theta -= 2.0 * piValue;
  if (theta < -piValue) theta += 2.0 * piValue;
  theta *= sn;

  double x = (ra * sin(theta)) + map.xo;
  double y = (ro - ra * cos(theta)) + map.yo;
  x = x + 1.5;
  y = y + 1.5;
  return WeatherMapXY(x.toInt(), y.toInt());
}

// 실시간 위치 가져오기 및 격자 좌표 변환
Future<WeatherMapXY> getCurrentLocationAndConvert() async {
  // 사용자의 현재 위치 권한 상태를 확인
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // 권한 거부됨
      throw Exception('위치 정보 권한이 거부되었습니다.');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // 권한이 영구적으로 거부됨
    throw Exception('위치 정보 권한이 영구적으로 거부되었습니다.');
  }

  // 현재 위치를 가져옴
  Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high);

  // 현재 위치(위도, 경도)를 기상청 API 격자 좌표로 변환
  WeatherMapXY mapXY = changeLatLngToMap(position.longitude, position.latitude);

  return mapXY;
}
