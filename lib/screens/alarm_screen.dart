import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alarm.dart';
import '../providers/alarm_provider.dart';

class AlarmScreen extends StatefulWidget {
  final Alarm? alarm;
  final int? index;

  const AlarmScreen({super.key, this.alarm, this.index});

  @override
  AlarmScreenState createState() => AlarmScreenState();
}

class AlarmScreenState extends State<AlarmScreen> {
  TimeOfDay _selectedTime = TimeOfDay.now();
  final TextEditingController _titleController = TextEditingController();
  List<bool> _repeatDays = List.filled(7, false);

  @override
  void initState() {
    super.initState();
    if (widget.alarm != null) {
      _selectedTime = widget.alarm!.time;
      _titleController.text = widget.alarm!.title;
      _repeatDays = widget.alarm!.repeatDays;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.alarm == null ? '새 알람 추가' : '알람 수정'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: Text('알람 시간: ${_selectedTime.format(context)}'),
              onTap: _pickTime,
            ),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '알람 제목'),
            ),
            const SizedBox(height: 20),
            const Text('반복 설정:'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: List.generate(7, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _repeatDays[index] = !_repeatDays[index];
                    });
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        _repeatDays[index] ? Colors.blue : Colors.grey,
                    child: Text(
                      ['월', '화', '수', '목', '금', '토', '일'][index],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveAlarm,
              child: Text(widget.alarm == null ? '알람 추가' : '알람 수정'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _saveAlarm() {
    final title = _titleController.text;
    final newAlarm = Alarm(
      id: widget.index ?? DateTime.now().millisecondsSinceEpoch,
      time: _selectedTime,
      title: title,
      repeatDays: _repeatDays,
    );

    final alarmProvider = Provider.of<AlarmProvider>(context, listen: false);
    if (widget.index == null) {
      alarmProvider.addAlarm(newAlarm);
    } else {
      alarmProvider.updateAlarm(widget.index!, newAlarm);
    }

    Navigator.pop(context);
  }
}
