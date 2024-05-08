import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Map<String, int>?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 위치 서비스가 활성화되어 있는지 확인
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // 위치 서비스를 활성화 시키도록 요청 (선택적)
      return Future.error('Location services are disabled.');
    }

    // 위치 권한 상태 확인
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // 권한이 거부되면 에러 반환
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // 권한이 영구적으로 거부된 경우, 설정으로 유도
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // 현재 위치 반환
    Position position = await Geolocator.getCurrentPosition();

    // 위도와 경도를 정수로 변환
    return {
      'nx': position.latitude.round(),
      'ny': position.longitude.round(),
    };
  }
}
