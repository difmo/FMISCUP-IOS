import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fmiscup/globalclass.dart';
import 'AlarmService.dart';
import 'floodmanagementscreen.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestNotificationPermission();
  final MethodChannel methodChannel = MethodChannel("alarm_channel");
  methodChannel.invokeListMethod("setAlarms");
  await methodChannel.invokeMethod("requestExactAlarmPermission");
  _listenMethod();
  runApp(const MyApp());
}

void _listenMethod() {
  final methodChannel = MethodChannel("alarm_channel");
  methodChannel.setMethodCallHandler((call) async {
    if (call.method == "setAlarms") {
      GlobalClass.customToast("hollfflhk");
    }
  });
}

Future<void> requestNotificationPermission() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FMIS-UP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: FloodManagementSplashScreen(),
    );
  }
}
