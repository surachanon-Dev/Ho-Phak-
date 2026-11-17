import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'views/auth/welcome_view.dart';

void main() {
  runApp(const HophakApp());
}

class HophakApp extends StatelessWidget {
  const HophakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hophak MFU',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const WelcomeView(),
    );
  }
}