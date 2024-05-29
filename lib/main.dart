import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_voice_alarm/providers/alarm_provider.dart';
import 'package:flutter_voice_alarm/screens/alarm_list_screen.dart';
import 'package:flutter_voice_alarm/screens/weather_screen.dart';
import 'package:flutter_voice_alarm/utils/alarm_helper.dart';
import 'package:flutter_voice_alarm/utils/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  tz.initializeTimeZones();
  await AlarmHelper.initialize();

  final permissionHandler = PermissionHandler();
  await permissionHandler.requestAllPermissions();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AlarmProvider()),
      ],
      child: const MyApp(),
    ),
  );
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm App'),
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
