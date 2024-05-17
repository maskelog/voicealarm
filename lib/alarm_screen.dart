import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'alarm_info.dart';

class AlarmScreen extends StatelessWidget {
  final AlarmInfo alarm;
  final AudioPlayer audioPlayer;

  const AlarmScreen(
      {super.key, required this.alarm, required this.audioPlayer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알람 울림'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              alarm.name,
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            Text(
              alarm.getTimeString(),
              style: const TextStyle(fontSize: 36),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                audioPlayer.stop();
                Navigator.of(context).pop();
              },
              child: const Text('알람 해제', style: TextStyle(fontSize: 24)),
            ),
          ],
        ),
      ),
    );
  }
}
