import 'package:flutter/material.dart';

import '../core/app_services.dart';
import '../core/utils/error_handling.dart' as core;
import '../features/auth/screens/login_screen.dart';

/// แสดง error จาก API; ถ้า token หมดอายุ (401) จะล้าง session แล้วพากลับหน้า login
void showApiError(BuildContext context, AppServices services, Object error) {
  core.showApiError(
    context,
    error,
    onUnauthorized: () {
      services.tokens.clear();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen(services: services)),
        (route) => false,
      );
    },
  );
}
