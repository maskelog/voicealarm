import 'package:flutter/material.dart';

class Alarm {
  final int id;
  final TimeOfDay time;
  final String title;
  final List<bool> repeatDays; // [Mon, Tue, Wed, Thu, Fri, Sat, Sun]

  Alarm(
      {required this.id,
      required this.time,
      required this.title,
      required this.repeatDays});
}
