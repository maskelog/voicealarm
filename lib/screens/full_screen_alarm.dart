import 'package:flutter/material.dart';

class FullScreenAlarmScreen extends StatelessWidget {
  const FullScreenAlarmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            Navigator.of(context).pop();
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Text('Alarm Ringing!', style: TextStyle(fontSize: 24)),
              Positioned(
                top: 40,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 40),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
