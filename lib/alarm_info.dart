class AlarmInfo {
  DateTime time;
  Map<String, bool> repeatDays;
  bool isEnabled;
  String sound;
  String name;

  AlarmInfo({
    required this.time,
    required this.repeatDays,
    this.isEnabled = true,
    this.sound = 'default_sound.mp3',
    this.name = '',
  });
}
