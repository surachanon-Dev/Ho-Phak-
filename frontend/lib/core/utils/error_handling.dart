import 'package:flutter/material.dart';

import '../network/api_client.dart';

/// แสดง error จาก API ให้ผู้ใช้เห็น
/// ถ้า token หมดอายุหรือไม่ถูกต้อง (401) จะเรียก [onUnauthorized] ให้แอปพากลับหน้า login
/// (รับเป็น callback เพื่อไม่ให้ core ต้อง import หน้าจอของ feature)
void showApiError(
  BuildContext context,
  Object error, {
  required VoidCallback onUnauthorized,
}) {
  if (error is ApiException && error.isUnauthorized) {
    onUnauthorized();
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
