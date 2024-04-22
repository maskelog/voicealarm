import 'dart:math';

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

WeatherMapXY changeLatLngToMap(double longitude, double latitude) {
  const double piValue = pi;
  const double degRad = piValue / 180.0;

  LamcParameter map = LamcParameter(
    re: 6371.00877,
    grid: 5.0,
    slat1: 30.0,
    slat2: 60.0,
    olon: 126.0,
    olat: 38.0,
    xo: 210 / 5.0,
    yo: 675 / 5.0,
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
