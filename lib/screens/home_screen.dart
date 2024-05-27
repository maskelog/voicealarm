import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_alarm_clock/model/model.dart';
import 'package:flutter_alarm_clock/provider/alarm_provider.dart';
import 'package:flutter_alarm_clock/utils/alarm_helper.dart';
import 'package:provider/provider.dart';
import 'weather_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm App'),
      ),
      body: Column(
        children: [
          const WeatherScreen(), // WeatherScreen 추가
          Expanded(
            child: Consumer<AlarmProvider>(
              builder: (context, alarmProvider, child) {
                return ListView.builder(
                  itemCount: alarmProvider.alarmList.length,
                  itemBuilder: (context, index) {
                    final alarm = alarmProvider.alarmList[index];
                    return Card(
                      child: ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alarm.label,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              alarm.when,
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: Text(
                          alarm.dateTime,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        onTap: () {
                          // 알람 수정 기능 추가
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
          ElevatedButton(
            onPressed: () => _setAlarm(), // 알람 설정 버튼
            child: const Text('Set Test Alarm'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 알람 추가 화면으로 이동
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
                alarmProvider
                    .cancelNotification(alarmProvider.alarmList[index].id);
                alarmProvider.alarmList.removeAt(index);
                alarmProvider.setData();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> _setAlarm() async {
    final now = DateTime.now().add(const Duration(seconds: 5));
    final alarmModel = Model(
      label: '테스트 알람',
      dateTime: now.toIso8601String(),
      check: true,
      when: '5초 후',
      id: 0,
      milliseconds: now.millisecondsSinceEpoch,
    );
    await AlarmHelper.scheduleAlarm(alarmModel); // 수정된 scheduleAlarm 호출
  }
}