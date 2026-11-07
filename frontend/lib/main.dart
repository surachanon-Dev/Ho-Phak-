import 'package:flutter/material.dart';

import 'models/user.dart';
import 'screens/home_router.dart';
import 'screens/welcome_screen.dart';
import 'ui/app_theme.dart';
import 'services/app_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = AppServices();
  await services.tokens.load();
  runApp(HopakOwnerApp(services: services));
}

class HopakOwnerApp extends StatelessWidget {
  const HopakOwnerApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hopak Owner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: _BootScreen(services: services),
    );
  }
}

/// ถ้ามี token เก็บไว้ ให้เรียก /api/me ตรวจสิทธิ์ก่อนเข้าแอป
/// ถ้าไม่มี token หรือ token ใช้ไม่ได้ ให้ไปหน้า login
class _BootScreen extends StatefulWidget {
  const _BootScreen({required this.services});

  final AppServices services;

  @override
  State<_BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<_BootScreen> {
  @override
  void initState() {
    super.initState();
    // ต้องรอให้ frame แรกสร้างเสร็จก่อน ไม่งั้น pushReplacement จะเรียกระหว่าง build
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    CurrentUser? user;
    if (widget.services.tokens.token != null) {
      try {
        user = await widget.services.auth.currentUser();
        if (user.isSuspended) {
          await widget.services.auth.logout();
          user = null;
        }
      } catch (_) {
        // token หมดอายุหรือ server ไม่พร้อม ให้ login ใหม่
        user = null;
      }
    }
    if (!mounted) return;
    final next = user == null
        ? WelcomeScreen(services: widget.services)
        : homeFor(widget.services, user);
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => next));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
