import 'package:flutter/material.dart';
import 'package:rentalkuy/views/getStarted.dart';
import 'package:rentalkuy/views/login.dart';
import 'package:device_preview/device_preview.dart';

void main() {
  runApp(DevicePreview(enabled: true, builder: (context) => const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      title: 'Flutter Demo',
      home: const Login(),
    );
  }
}
