import 'package:flutter/material.dart';

import 'views/screens/login_screen.dart';
import 'views/theme/owner_theme.dart';

/// จุดเข้าของฝั่ง owner เริ่มที่หน้าเข้าสู่ระบบเสมอ (ข้อมูลอยู่ในหน่วยความจำ ยังไม่มีการจำการล็อกอิน)
class OwnerApp extends StatelessWidget {
  const OwnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hopak Owner',
      debugShowCheckedModeBanner: false,
      theme: buildOwnerTheme(),
      home: const LoginScreen(),
    );
  }
}
