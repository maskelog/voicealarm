import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_voice_alarm/models/model.dart';
import 'package:flutter_voice_alarm/providers/alarm_provider.dart';
import 'package:flutter_voice_alarm/utils/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AddAlarm extends StatefulWidget {
  const AddAlarm({super.key});

  @override
  State<AddAlarm> createState() => _AddAlarmState();
}

class _AddAlarmState extends State<AddAlarm> {
  late TextEditingController controller;

  String? dateTime;
  bool repeat = false;

  DateTime? notificationTime;

  String? name = "none";
  int? milliseconds;

  final PermissionHandler _permissionHandler = PermissionHandler();

  @override
  void initState() {
    controller = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AlarmProvider>(context, listen: false).getData();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: const [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.check),
          )
        ],
        automaticallyImplyLeading: true,
        title: const Text(
          'Add Alarm',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.3,
            width: MediaQuery.of(context).size.width,
            child: Center(
              child: CupertinoDatePicker(
                showDayOfWeek: true,
                minimumDate: DateTime.now(),
                dateOrder: DatePickerDateOrder.dmy,
                onDateTimeChanged: (va) {
                  setState(() {
                    dateTime = DateFormat().add_jms().format(va);
                    milliseconds = va.millisecondsSinceEpoch;
                    notificationTime = va;
                  });
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: CupertinoTextField(
                placeholder: "Add Label",
                controller: controller,
              ),
            ),
          ),
          Row(
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Repeat daily"),
              ),
              CupertinoSwitch(
                value: repeat,
                onChanged: (bool value) {
                  setState(() {
                    repeat = value;
                    name = repeat ? "Everyday" : "none";
                  });
                },
              ),
            ],
          ),
          ElevatedButton(
            onPressed: _handleSaveAlarm,
            child: const Text("Set Alarm"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSaveAlarm() async {
    bool permissionGranted = await _permissionHandler.requestAlarmPermission();

    if (permissionGranted) {
      _saveAlarm();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('알람 설정 권한이 필요합니다. 설정에서 권한을 허용해주세요.'),
        ),
      );
    }
  }

  void _saveAlarm() {
    Random random = Random();
    int randomNumber = random.nextInt(100);

    final alarmProvider = Provider.of<AlarmProvider>(context, listen: false);

    final alarm = Model(
      label: controller.text,
      dateTime: dateTime!,
      check: true,
      when: name!,
      id: randomNumber,
      milliseconds: milliseconds!,
    );

    alarmProvider.setAlarm(alarm);
    alarmProvider.setData();
    alarmProvider.scheduleNotification(notificationTime!, randomNumber);

    Navigator.pop(context);
  }
}
