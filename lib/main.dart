import 'package:flutter/material.dart';
import 'package:flutter_voice_alarm/utils/alarm_helper.dart';
import 'package:flutter_voice_alarm/utils/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';
import 'providers/alarm_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  await AlarmHelper.initializeNotifications();
  await dotenv.load(fileName: ".env");

  PermissionHandler permissionHandler = PermissionHandler();
  await permissionHandler.requestAllPermissions(); // 모든 필요한 권한 요청

  runApp(
    ChangeNotifierProvider(
      create: (context) => AlarmProvider(),
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
