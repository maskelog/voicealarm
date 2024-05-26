import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/alarm_provider.dart';
import 'alarm_screen.dart';
import 'weather_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const WeatherScreen(), // 현재 위치의 날씨 정보를 표시
            Expanded(
              child: Consumer<AlarmProvider>(
                builder: (context, alarmProvider, child) {
                  return ListView.builder(
                    itemCount: alarmProvider.alarms.length,
                    itemBuilder: (context, index) {
                      final alarm = alarmProvider.alarms[index];
                      return Card(
                        child: ListTile(
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alarm.title,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                alarm.repeatDays.every((day) => day)
                                    ? '매일 반복'
                                    : alarm.repeatDays
                                        .asMap()
                                        .entries
                                        .where((entry) => entry.value)
                                        .map((entry) => [
                                              '월',
                                              '화',
                                              '수',
                                              '목',
                                              '금',
                                              '토',
                                              '일'
                                            ][entry.key])
                                        .join(', '),
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: Text(
                            alarm.time.format(context),
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AlarmScreen(
                                  alarm: alarm,
                                  index: index,
                                ),
                              ),
                            );
                          },
                          onLongPress: () {
                            _showDeleteDialog(context, alarmProvider, index);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AlarmScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, AlarmProvider alarmProvider, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('알람 삭제'),
          content: const Text('정말로 이 알람을 삭제하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('삭제'),
              onPressed: () {
                alarmProvider.removeAlarm(index);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
