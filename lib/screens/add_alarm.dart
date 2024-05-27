import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_voice_alarm/providers/alarm_provider.dart';

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

  @override
  void initState() {
    controller = TextEditingController();
    context.read<AlarmProvider>().getData();
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
                dateTime = DateFormat().add_jms().format(va);

                milliseconds = va.microsecondsSinceEpoch;

                notificationTime = va;

                print(dateTime);
              },
            )),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: CupertinoTextField(
                  placeholder: "Add Label",
                  controller: controller,
                )),
          ),
          Row(
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(" Repeat daily"),
              ),
              CupertinoSwitch(
                value: repeat,
                onChanged: (bool value) {
                  repeat = value;

                  if (repeat == false) {
                    name = "none";
                  } else {
                    name = "Everyday";
                  }

                  setState(() {});
                },
              ),
            ],
          ),
          ElevatedButton(
              onPressed: () {
                Random random = Random();
                int randomNumber = random.nextInt(100);

                context.read<AlarmProvider>().setAlarm(controller.text,
                    dateTime!, true, name!, randomNumber, milliseconds!);
                context.read<AlarmProvider>().setData();

                context
                    .read<AlarmProvider>()
                    .scheduleNotification(notificationTime!, randomNumber);

                Navigator.pop(context);
              },
              child: const Text("Set Alarm")),
        ],
      ),
    );
  }
}
