// ผู้รับผิดชอบ: Karn (นักศึกษา)
// ทดสอบหน้า: หน้าต้อนรับ เข้าสู่ระบบ และสมัครสมาชิก (welcome, login, register)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/auth/login/login_screen.dart';
import 'package:hopak_frontend/features/auth/register/register_screen.dart';
import 'package:hopak_frontend/features/auth/welcome/welcome_screen.dart';

import '../../../helpers/admin_test_helpers.dart';
import '../../../helpers/test_services.dart';

void main() {
  testWidgets('หน้าต้อนรับแสดงชื่อแอป', (tester) async {
    final services = studentServicesWith((req) async => jsonResponse({}));

    await tester.pumpWidget(MaterialApp(home: WelcomeScreen(services: services)));
    await tester.pumpAndSettle();

    expect(find.text('Ho-Phak'), findsOneWidget);
    expect(find.textContaining('ยินดีต้อนรับสู่'), findsOneWidget);
  });

  testWidgets('เข้าสู่ระบบส่งเบอร์และรหัสผ่านไปที่ /api/login', (tester) async {
    final bodies = <String>[];
    final services = studentServicesWith((req) async {
      if (req.url.path == '/api/login') bodies.add(req.body);
      return jsonResponse({'message': 'เบอร์หรือ password ไม่ถูกต้อง'}, 401);
    });

    await tester.pumpWidget(MaterialApp(home: LoginScreen(services: services)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '0812345678');
    await tester.enterText(find.byType(TextFormField).at(1), 'Password-1');
    await tester.tap(find.widgetWithText(FilledButton, 'เข้าสู่ระบบ'));
    await tester.pumpAndSettle();

    expect(bodies, isNotEmpty);
    expect(bodies.first, contains('0812345678'));
  });

  testWidgets('ปุ่ม สมัครสมาชิก เปิดหน้าสมัครสมาชิก', (tester) async {
    final services = studentServicesWith((req) async => jsonResponse({}));

    await tester.pumpWidget(MaterialApp(home: LoginScreen(services: services)));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'สมัครสมาชิก'));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
  });
}
