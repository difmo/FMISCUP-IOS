import 'dart:io';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:fmiscup/globalclass.dart';
import 'splash_screen.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  await requestNotificationPermission();
  final MethodChannel methodChannel = MethodChannel("alarm_channel");
  try {
    await methodChannel.invokeMethod("setAlarms");
  } on PlatformException catch (e) {
    print("Error calling setAlarms: ${e.message}");
  }

  try {
    await methodChannel.invokeMethod("requestExactAlarmPermission");
  } on PlatformException catch (e) {
    print("Error requesting exact alarm permission: ${e.message}");
  }
  _listenMethod();
  runApp(const MyApp());
}

void _listenMethod() {
  final methodChannel = MethodChannel("alarm_channel");
  methodChannel.setMethodCallHandler((call) async {
    if (call.method == "setAlarms") {
      GlobalClass.customToast("Alarm setup triggered from native");
    }
  });
}

Future<void> requestNotificationPermission() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}

// Root widget of the app
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

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
