import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alarm.dart';
import '../providers/alarm_provider.dart';
import '../screens/alarm_screen.dart';

class AlarmListTile extends StatelessWidget {
  final Alarm alarm;
  final int index;

  const AlarmListTile({super.key, required this.alarm, required this.index});

  @override
  Widget build(BuildContext context) {
    String repeatDays = _getRepeatDays(alarm.repeatDays);

    return ListTile(
      title: Text(alarm.title),
      subtitle: Text('${alarm.time.format(context)} - $repeatDays'),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () {
          final alarmProvider =
              Provider.of<AlarmProvider>(context, listen: false);
          alarmProvider.removeAlarm(index);
        },
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlarmScreen(alarm: alarm, index: index),
          ),
        );
      },
    );
  }

  String _getRepeatDays(List<bool> repeatDays) {
    if (repeatDays.every((day) => day)) {
      return '매일 반복';
    }
    List<String> days = ['월', '화', '수', '목', '금', '토', '일'];
    List<String> activeDays = [];
    for (int i = 0; i < repeatDays.length; i++) {
      if (repeatDays[i]) {
        activeDays.add(days[i]);
      }
    }
    return activeDays.join(', ');
  }
}
