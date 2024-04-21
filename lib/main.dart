import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'alarm_info.dart';
import 'alarm_manager.dart';
import 'weather_service.dart';

Future main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Alarm App',
      home: AlarmPage(),
    );
  }
}

class AlarmPage extends StatefulWidget {
  const AlarmPage({super.key});

  @override
  AlarmPageState createState() => AlarmPageState();
}

class AlarmPageState extends State<AlarmPage> {
  List<AlarmInfo> alarms = [];
  late AlarmManager alarmManager;

  @override
  void initState() {
    super.initState();
    alarmManager = AlarmManager(WeatherService());
  }

  void _addOrUpdateAlarm(AlarmInfo alarm) {
    setState(() {
      int index = alarms.indexWhere((a) => a.time == alarm.time);
      if (index != -1) {
        alarms[index] = alarm;
      } else {
        alarms.add(alarm);
      }
    });
  }

  void _deleteAlarm(int index) {
    setState(() {
      alarms.removeAt(index);
    });
  }

  void _showAddAlarmDialog({AlarmInfo? initialAlarm}) {
    TextEditingController nameController =
        TextEditingController(text: initialAlarm?.name ?? '');
    Map<String, bool> repeatDays = initialAlarm?.repeatDays ??
        {
          'Mon': false,
          'Tue': false,
          'Wed': false,
          'Thu': false,
          'Fri': false,
          'Sat': false,
          'Sun': false
        };
    TimeOfDay selectedTime = initialAlarm != null
        ? TimeOfDay(
            hour: initialAlarm.time.hour, minute: initialAlarm.time.minute)
        : TimeOfDay.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Alarm'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Alarm Name'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (pickedTime != null && pickedTime != selectedTime) {
                      setState(() {
                        selectedTime = pickedTime;
                      });
                    }
                  },
                  child: Text('Select Time: ${selectedTime.format(context)}'),
                ),
                ...repeatDays.keys.map((day) {
                  bool isSelected = repeatDays[day] ?? false;
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: isSelected ? Colors.blue : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        repeatDays[day] = !isSelected;
                      });
                    },
                    child: Text(day),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                Navigator.of(context).pop();
                _addOrUpdateAlarm(AlarmInfo(
                  name: nameController.text.trim(),
                  time: DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                    selectedTime.hour,
                    selectedTime.minute,
                  ),
                  repeatDays: repeatDays,
                  isEnabled: initialAlarm?.isEnabled ?? true,
                ));
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedTime = DateFormat('h:mm a').format(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: const Text('보이스 알람'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              formattedTime,
              style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: alarms.length,
              itemBuilder: (context, index) {
                final alarm = alarms[index];
                return ListTile(
                  title: Text(
                      '${alarm.name} ${alarm.time.hour.toString().padLeft(2, '0')}:${alarm.time.minute.toString().padLeft(2, '0')}'),
                  subtitle: Text(alarm.repeatDays.keys
                      .where((day) => alarm.repeatDays[day]!)
                      .join(', ')),
                  onTap: () => _showAddAlarmDialog(initialAlarm: alarm),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: alarm.isEnabled,
                        onChanged: (bool value) {
                          setState(() {
                            alarm.isEnabled = value;
                          });
                        },
                        activeColor: Colors.red,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteAlarm(index),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAlarmDialog,
        tooltip: 'Add Alarm',
        child: const Icon(Icons.add),
      ),
    );
  }
}
