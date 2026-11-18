import 'package:flutter/material.dart';

import 'package:hopak_frontend/features/auth/login/login_screen.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:hopak_frontend/core/app_services.dart';

/// แสดง error จาก API ให้ผู้ใช้เห็น
/// ถ้า token หมดอายุหรือไม่ถูกต้อง (401) จะล้าง session แล้วพากลับหน้า login
void showApiError(BuildContext context, AppServices services, Object error) {
  if (error is ApiException && error.isUnauthorized) {
    services.tokens.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen(services: services)),
      (route) => false,
    );
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('กรุณาเข้าสู่ระบบใหม่อีกครั้ง')),
    );
    return;
  }

  final message = error is ApiException ? error.message : error.toString();
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.error,
    ),
  );
}
