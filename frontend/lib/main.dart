import 'package:flutter/material.dart';

import 'app/home_router.dart';
import 'core/app_services.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'shared/models/user.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = AppServices();
  await services.tokens.load();
  runApp(HopakApp(services: services));
}

class HopakApp extends StatelessWidget {
  const HopakApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ho-Phak',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: _BootScreen(services: services),
    );
  }
}

/// ถ้ามี token เก็บไว้ ให้เรียก /api/me ตรวจสิทธิ์ก่อนเข้าแอป
/// ถ้าไม่มี token หรือ token ใช้ไม่ได้ ให้ไปหน้า welcome
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
    // รอ frame แรกก่อน ไม่งั้น pushReplacement จะเรียกระหว่าง build
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
        user = null; // token หมดอายุหรือ server ไม่พร้อม ให้ login ใหม่
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
