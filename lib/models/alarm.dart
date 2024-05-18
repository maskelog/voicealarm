import 'package:flutter/material.dart';

class Alarm {
  final int id;
  final TimeOfDay time;
  final String title;
  final List<bool> repeatDays;

  Alarm({
    required this.id,
    required this.time,
    required this.title,
    required this.repeatDays,
  });

  Alarm.create({
    required this.time,
    required this.title,
    required this.repeatDays,
  }) : id = DateTime.now().millisecondsSinceEpoch;
}
