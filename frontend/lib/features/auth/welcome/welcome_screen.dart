import 'package:flutter/material.dart';

import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/core/theme/app_theme.dart';
import 'package:hopak_frontend/features/auth/login/login_screen.dart';
import 'package:hopak_frontend/features/auth/register/register_screen.dart';
import 'package:hopak_frontend/features/auth/widgets/auth_widgets.dart';

/// หน้าแรกก่อน login: โลโก้ + ปุ่มเข้าสู่ระบบ / สมัครสมาชิก (จัดกลางจอ กว้างไม่เกิน 420)
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.services});

  final AppServices services;

  void _openLogin(BuildContext context, {String? phone}) => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => LoginScreen(services: services, initialId: phone)),
  );

  /// สมัครเสร็จแล้วพาไปหน้าเข้าสู่ระบบ พร้อมเติมเบอร์ที่เพิ่งสมัครให้
  Future<void> _openRegister(BuildContext context) async {
    final phone = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => RegisterScreen(services: services)),
    );
    if (phone != null && context.mounted) _openLogin(context, phone: phone);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: HoPhakLogo(size: 96)),
                  const SizedBox(height: 40),
                  Text(
                    'ยินดีต้อนรับสู่ Ho-Phak',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'ค้นหาหอพักใกล้มหาวิทยาลัยแม่ฟ้าหลวง',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 40),
                  FilledButton(
                    key: const Key('welcome_login'),
                    onPressed: () => _openLogin(context),
                    child: const Text('เข้าสู่ระบบ'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    key: const Key('welcome_register'),
                    onPressed: () => _openRegister(context),
                    child: const Text('สมัครสมาชิก'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
