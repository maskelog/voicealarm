import 'package:flutter/material.dart';
import 'package:flutter_alarm_clock/screen/alarm_list_screen.dart';
import 'package:flutter_alarm_clock/screen/weather_screen.dart';
import 'package:flutter_alarm_clock/utils/alarm_helper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  tz.initializeTimeZones();
  await AlarmHelper.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alarm App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알람 앱'),
      ),
      body: const Column(
        children: [
          WeatherScreen(),
          Expanded(
            child: AlarmListScreen(),
          ),
        ],
      ),
    );
  }
}