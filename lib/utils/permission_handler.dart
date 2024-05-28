import 'package:permission_handler/permission_handler.dart';

class PermissionHandler {
  /// 위치 권한 요청
  Future<bool> requestLocationPermission() async {
    PermissionStatus status = await Permission.location.status;
    if (status.isGranted) {
      return true;
    } else {
      status = await Permission.location.request();
      return status.isGranted;
    }
  }

  /// 알람 권한 요청 (Android 12 이상)
  Future<bool> requestAlarmPermission() async {
    PermissionStatus status = await Permission.scheduleExactAlarm.status;
    if (status.isGranted) {
      return true;
    } else {
      status = await Permission.scheduleExactAlarm.request();
      return status.isGranted;
    }
  }

  /// 모든 필요한 권한 요청
  Future<void> requestAllPermissions() async {
    await requestLocationPermission();
    await requestAlarmPermission();
  }
}
