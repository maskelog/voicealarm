import 'package:flutter/material.dart';
import 'package:flutter_voice_alarm/models/model.dart';

class Alarm {
  final int id;
  final TimeOfDay time;
  final String title;
  final List<bool> repeatDays; // [Mon, Tue, Wed, Thu, Fri, Sat, Sun]

  Alarm({
    required this.id,
    required this.time,
    required this.title,
    required this.repeatDays,
  });

  Model toModel() {
    return Model(
      label: title,
      dateTime: DateTime.now().toIso8601String(),
      check: true,
      when: '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
      id: id,
      milliseconds: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
