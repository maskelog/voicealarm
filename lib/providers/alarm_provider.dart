import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_voice_alarm/main.dart';
import 'package:flutter_voice_alarm/models/model.dart';
import 'package:flutter_voice_alarm/screens/full_screen_alarm.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

class AlarmProvider extends ChangeNotifier {
  late SharedPreferences preferences;

  List<Model> alarmList = [];

  List<String> listOfString = [];

  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;

  late BuildContext context;

  void setAlarm(Model alarm) {
    alarmList.add(alarm);
    setData();
  }

  void updateAlarm(int index, Model alarm) {
    alarmList[index] = alarm;
    setData();
  }

  void removeAlarm(int index) {
    cancelNotification(alarmList[index].id);
    alarmList.removeAt(index);
    setData();
  }

  Future<void> getData() async {
    preferences = await SharedPreferences.getInstance();

    List<String>? comingList = preferences.getStringList("data");

    if (comingList != null) {
      alarmList =
          comingList.map((e) => Model.fromJson(json.decode(e))).toList();
    }
    notifyListeners();
  }

  void setData() {
    listOfString = alarmList.map((e) => json.encode(e.toJson())).toList();
    preferences.setStringList("data", listOfString);
    notifyListeners();
  }

  Future<void> initialize(BuildContext con) async {
    context = con;
    var androidInitialize =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    var iOSInitialize = const DarwinInitializationSettings();
    var initializationSettings =
        InitializationSettings(android: androidInitialize, iOS: iOSInitialize);
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin!.initialize(initializationSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);
  }

  void onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (notificationResponse.payload != null) {
      debugPrint('notification payload: $payload');
    }
    await Navigator.push(
        context, MaterialPageRoute<void>(builder: (context) => const MyApp()));
  }

  Future<void> showNotification() async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'your channel id',
      'your channel name',
      channelDescription: 'your channel description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
    await flutterLocalNotificationsPlugin!.show(
        0, 'plain title', 'plain body', notificationDetails,
        payload: 'item x');
  }

  Future<void> scheduleNotification(DateTime dateTime, int randomNumber) async {
    int newTime =
        dateTime.millisecondsSinceEpoch - DateTime.now().millisecondsSinceEpoch;
    await flutterLocalNotificationsPlugin!.zonedSchedule(
        randomNumber,
        'Alarm Clock',
        DateFormat().format(DateTime.now()),
        tz.TZDateTime.now(tz.local).add(Duration(milliseconds: newTime)),
        const NotificationDetails(
            android: AndroidNotificationDetails(
                'your channel id', 'your channel name',
                channelDescription: 'your channel description',
                sound: RawResourceAndroidNotificationSound("alarm"),
                autoCancel: false,
                playSound: true,
                priority: Priority.max)),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime);
  }

  Future<void> cancelNotification(int notificationId) async {
    await flutterLocalNotificationsPlugin!.cancel(notificationId);
  }

  static Future<void> alarmCallback() async {
    print('Alarm callback triggered!');

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'alarm_channel',
      'Alarm Channel',
      channelDescription: 'Channel for Alarm notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
      fullScreenIntent: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin.show(
        0, 'Alarm', 'It\'s time!', platformChannelSpecifics,
        payload: 'Alarm payload');

    WidgetsFlutterBinding.ensureInitialized();
    runApp(const MaterialApp(home: FullScreenAlarmScreen()));
  }
}
