import 'package:flutter/material.dart';

import 'package:hopak_frontend/core/theme/app_theme.dart';

/// โลโก้ Ho-Phak: กล่องสีหลักมุมโค้ง + ไอคอนบ้าน (ใช้ในหน้าเข้าสู่ระบบและสมัครสมาชิก)
class HoPhakLogo extends StatelessWidget {
  const HoPhakLogo({super.key, this.size = 88, this.showName = true});

  final double size;

  /// แสดงชื่อแอปและสโลแกนใต้โลโก้
  final bool showName;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(size * 0.24),
          ),
          child: Icon(Icons.home_work_rounded, color: Colors.white, size: size * 0.52),
        ),
        if (showName) ...[
          const SizedBox(height: 12),
          const Text(
            'Ho-Phak',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Find your place, feel at home.',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }
}

/// ข้อความลิงก์ท้ายฟอร์ม เช่น "ยังไม่มีบัญชี? สมัครสมาชิก"
class AuthSwitchLink extends StatelessWidget {
  const AuthSwitchLink({super.key, required this.question, required this.action, required this.onPressed});

  final String question;
  final String action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(question),
        TextButton(onPressed: onPressed, child: Text(action)),
      ],
    );
  }
}

/// ข้อความ error สีแดงใต้ฟอร์ม
class AuthFormError extends StatelessWidget {
  const AuthFormError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(message, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
  );
}
