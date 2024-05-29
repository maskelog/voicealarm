import 'package:flutter/material.dart';
import 'package:flutter_voice_alarm/models/model.dart';
import 'package:flutter_voice_alarm/utils/alarm_helper.dart';
import 'package:provider/provider.dart';
import '../providers/alarm_provider.dart';

class AlarmListScreen extends StatefulWidget {
  const AlarmListScreen({super.key});

  @override
  AlarmListScreenState createState() => AlarmListScreenState();
}

class AlarmListScreenState extends State<AlarmListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AlarmProvider>(context, listen: false).getData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AlarmProvider>(
      builder: (context, alarmProvider, child) {
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: alarmProvider.alarmList.length,
                itemBuilder: (context, index) {
                  final alarm = alarmProvider.alarmList[index];
                  return Card(
                    child: ListTile(
                      title: Text(alarm.label),
                      subtitle: Text(alarm.when),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          alarmProvider.removeAlarm(index);
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
                    await _scheduleAlarm(picked);
                  }
                },
                child: const Text('알람 추가'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _scheduleAlarm(TimeOfDay picked) async {
    DateTime now = DateTime.now();
    DateTime dateTime = DateTime(
      now.year,
      now.month,
      now.day,
      picked.hour,
      picked.minute,
    );

    // Ensure the datetime is in the future
    if (dateTime.isBefore(now)) {
      dateTime = dateTime.add(const Duration(days: 1));
    }

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
      Provider.of<AlarmProvider>(context, listen: false)
          .alarmList
          .add(alarmModel);
    });
  }
}
