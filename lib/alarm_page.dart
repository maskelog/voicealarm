import 'package:flutter/material.dart';

class Alarm {
  TimeOfDay time;
  DateTime date;
  List<bool> days;
  bool isEnabled;

  Alarm(this.time, this.date, this.days, this.isEnabled);
}

// 알람 설정 페이지
class AlarmSettingPage extends StatefulWidget {
  const AlarmSettingPage({super.key});

  @override
  AlarmSettingPageState createState() => AlarmSettingPageState();
}

class AlarmSettingPageState extends State<AlarmSettingPage> {
  List<Alarm> alarms = [];
  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime _selectedDate = DateTime.now();
  final List<bool> _selectedDays = List.generate(7, (index) => false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알람 설정'),
      ),
      body: Column(
        children: <Widget>[
          // 시간 선택
          ListTile(
            title: Text('시간: ${_selectedTime.format(context)}'),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (time != null) {
                setState(() {
                  _selectedTime = time;
                });
              }
            },
          ),
          // 날짜 선택
          ListTile(
            title: Text('날짜: ${_selectedDate.toString()}'),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2050),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                });
              }
            },
          ),
          // 요일 선택
          ToggleButtons(
            isSelected: _selectedDays,
            onPressed: (int index) {
              setState(() {
                _selectedDays[index] = !_selectedDays[index];
              });
            },
            children: const <Widget>[
              Text('월'),
              Text('화'),
              Text('수'),
              Text('목'),
              Text('금'),
              Text('토'),
              Text('일'),
            ],
          ),
          // 알람 설정 버튼
          ElevatedButton(
            child: const Text('알람 설정'),
            onPressed: () {
              setState(() {
                alarms.add(
                    Alarm(_selectedTime, _selectedDate, _selectedDays, true));
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('알람이 설정되었습니다.'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
