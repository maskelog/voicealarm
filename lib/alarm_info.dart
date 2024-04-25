class AlarmInfo {
  DateTime time;
  Map<String, bool> repeatDays;
  bool isEnabled;
  String sound;
  String name;
  int nx;
  int ny;

  AlarmInfo({
    required this.time,
    required this.repeatDays,
    this.isEnabled = true,
    this.sound = 'default_sound.mp3',
    this.name = '',
    required this.nx,
    required this.ny,
  });
}
