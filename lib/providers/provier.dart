import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_voice_alarm/main.dart';
import 'package:flutter_voice_alarm/models/model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

class AlarmProvider extends ChangeNotifier {
  late SharedPreferences preferences;

  List<Model> modelist = [];

  List<String> listofstring = [];

  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;

  late BuildContext context;

  void setAlaram(String label, String dateTime, bool check, String repeat,
      int id, int milliseconds) {
    modelist.add(Model(
        label: label,
        dateTime: dateTime,
        check: check,
        when: repeat,
        id: id,
        milliseconds: milliseconds));
    notifyListeners();
  }

  void editSwitch(int index, bool check) {
    modelist[index].check = check;
    notifyListeners();
  }

  Future<void> getData() async {
    preferences = await SharedPreferences.getInstance();

    List<String>? cominglist = preferences.getStringList("data");

    if (cominglist != null) {
      modelist = cominglist.map((e) => Model.fromJson(json.decode(e))).toList();
    } else {
      modelist = [];
    }

    notifyListeners();
  }

  void setData() {
    listofstring = modelist.map((e) => json.encode(e.toJson())).toList();
    preferences.setStringList("data", listofstring);

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

  Future<void> scheduleNotification(DateTime datetime, int randomNumber) async {
    int newTime =
        datetime.millisecondsSinceEpoch - DateTime.now().millisecondsSinceEpoch;
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
}
