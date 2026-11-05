import 'package:flutter/material.dart';

import 'screens/dormitory_list_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';

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
      home: const StartupScreen(),
    );
  }
}

// เช็ก token ที่เก็บไว้ตอนเปิดแอป ถ้ามีให้ไปหน้ารายการเลย
// ถ้า token หมดอายุ หน้ารายการจะพากลับไปหน้า login เอง
class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: ApiService.getToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snapshot.data != null ? const DormitoryListScreen() : const LoginScreen();
      },
    );
  }
}
