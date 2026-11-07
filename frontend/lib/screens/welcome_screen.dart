import 'package:flutter/material.dart';

import '../services/app_services.dart';
import '../ui/app_theme.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// หน้าแรกก่อน login ตามดีไซน์ "Welcome to Ho_Phak"
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to Ho_Phak',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'หอพักใกล้มหาวิทยาลัยแม่ฟ้าหลวง',
                style: TextStyle(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LoginScreen(services: services),
                  ),
                ),
                child: const Text('เข้าสู่ระบบ'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RegisterScreen(services: services),
                  ),
                ),
                child: const Text('ยังไม่มีบัญชี? สมัครสมาชิก'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
