import 'package:flutter/material.dart';

import 'screens/login_screen.dart';

void main() {
  runApp(const HopakApp());
}

class HopakApp extends StatelessWidget {
  const HopakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hopak Owner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const LoginScreen(),
    );
  }
}
