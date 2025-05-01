import 'package:flutter/material.dart';
import 'lupapassword.dart';

void main() {
  runApp(ForgotPasswordApp());
}

class ForgotPasswordApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ForgotPasswordScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
