// ผู้รับผิดชอบ: Karn (นักศึกษา)
// ไฟล์นี้เป็นเทสต์ widget ของลิงก์ลืมรหัสผ่านจากหน้า login
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/auth/screens/forgot_password_screen.dart';
import 'package:hopak_frontend/features/auth/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/admin_test_helpers.dart';
import '../../../helpers/test_services.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('หน้า login มีลิงก์ Forgot password? ไปหน้าวิธีรีเซ็ต', (tester) async {
    final services = studentServicesWith((req) async => jsonResponse({}));
    await tester.pumpWidget(MaterialApp(home: LoginScreen(services: services)));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Forgot password?'));
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    expect(find.text('Reset your password'), findsOneWidget);
  });
}
