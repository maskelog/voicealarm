import 'package:flutter/material.dart';

class AlarmInfo {
  int id; // 알람 고유 ID
  TimeOfDay time; // 알람 시간
  DateTime date; // 알람 날짜
  Map<String, bool> repeatDays; // 요일별 반복 여부
  bool isEnabled; // 알람 활성화 여부
  String sound; // 알람 소리 파일 이름
  String name; // 알람 이름
  int nx; // 기상청 API 격자 좌표 x
  int ny; // 기상청 API 격자 좌표 y

  AlarmInfo({
    required this.id,
    required this.time,
    required this.date,
    required this.repeatDays,
    this.isEnabled = true,
    this.sound = 'default_sound.mp3',
    this.name = '',
    required this.nx,
    required this.ny,
  });

  /// 요일별 알람 활성화 여부를 반환합니다.
  bool isActiveOnDay(String day) {
    return repeatDays[day] ?? false;
  }

  /// 시간을 'HH:mm' 형식의 문자열로 반환합니다.
  String getTimeString() {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// 알람의 전체 정보를 문자열로 반환합니다.
  @override
  String toString() {
    return 'AlarmInfo: $name at ${getTimeString()} on ${date.toIso8601String()}, Enabled: $isEnabled, Sound: $sound, Coordinates: ($nx, $ny)';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'time': {'hour': time.hour, 'minute': time.minute},
        'date': date.toIso8601String(),
        'repeatDays': repeatDays,
        'isEnabled': isEnabled,
        'sound': sound,
        'name': name,
        'nx': nx,
        'ny': ny,
      };

  factory AlarmInfo.fromJson(Map<String, dynamic> json) => AlarmInfo(
        id: json['id'],
        time: TimeOfDay(
            hour: json['time']['hour'], minute: json['time']['minute']),
        date: DateTime.parse(json['date']),
        repeatDays: Map<String, bool>.from(json['repeatDays']),
        isEnabled: json['isEnabled'],
        sound: json['sound'],
        name: json['name'],
        nx: json['nx'],
        ny: json['ny'],
      );
}
