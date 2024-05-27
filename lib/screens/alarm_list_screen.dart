import 'package:flutter/material.dart';
import 'package:flutter_voice_alarm/models/model.dart';
import 'package:flutter_voice_alarm/utils/alarm_helper.dart';

class AlarmListScreen extends StatelessWidget {
  const AlarmListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: 5, // 여기서는 예시로 5개의 알람을 표시합니다.
            itemBuilder: (context, index) {
              return Card(
                child: ListTile(
                  title: Text('알람 ${index + 1}'),
                  subtitle: const Text('07:00 AM'), // 여기에 실제 알람 시간을 넣습니다.
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      // 알람 삭제 로직을 여기에 추가합니다.
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
                _scheduleAlarm(context, picked);
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
  }
}
