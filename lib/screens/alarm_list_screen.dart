import 'package:flutter/material.dart';
import 'package:flutter_voice_alarm/models/model.dart';
import 'package:flutter_voice_alarm/utils/alarm_helper.dart';

class AlarmListScreen extends StatefulWidget {
  const AlarmListScreen({super.key});

  @override
  _AlarmListScreenState createState() => _AlarmListScreenState();
}

class _AlarmListScreenState extends State<AlarmListScreen> {
  List<Model> alarmList = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: alarmList.length,
            itemBuilder: (context, index) {
              return Card(
                child: ListTile(
                  title: Text(alarmList[index].label),
                  subtitle: Text(alarmList[index].when),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      _deleteAlarm(alarmList[index].id);
                      setState(() {
                        alarmList.removeAt(index);
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () async {
              TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );

              if (picked != null) {
                await _scheduleAlarm(context, picked);
              }
            },
            child: const Text('알람 추가'),
          ),
        ),
      ],
    );
  }

  Future<void> _scheduleAlarm(BuildContext context, TimeOfDay picked) async {
    DateTime now = DateTime.now();
    DateTime dateTime = DateTime(
      now.year,
      now.month,
      now.day,
      picked.hour,
      picked.minute,
    );

    final alarmModel = Model(
      label: '알람',
      dateTime: dateTime.toIso8601String(),
      check: true,
      when: picked.format(context),
      id: DateTime.now().millisecondsSinceEpoch,
      milliseconds: dateTime.millisecondsSinceEpoch,
    );

    await AlarmHelper.scheduleAlarm(alarmModel);
    setState(() {
      alarmList.add(alarmModel);
    });
  }

  void _deleteAlarm(int id) async {
    await AlarmHelper.cancelAlarm(id);
  }
}
