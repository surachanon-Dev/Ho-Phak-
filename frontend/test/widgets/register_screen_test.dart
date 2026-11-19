// ผู้รับผิดชอบ: Plub (Tester)
// ทดสอบหน้า: สมัครสมาชิก (lib/features/auth/register/register_screen.dart)
// ใช้ backend จำลอง (MockClient) จึงไม่ต้องเปิด server
// Run: flutter test test/widgets/register_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/auth/register/register_controller.dart';
import 'package:hopak_frontend/features/auth/register/register_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_services.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ลำดับช่องในหน้า: 0 ชื่อผู้ใช้, 1 เบอร์, 2 รหัสผ่าน, 3 ยืนยันรหัสผ่าน
  Finder submitButton() => find.widgetWithText(FilledButton, 'สมัครสมาชิก');
  const phoneError = 'เบอร์โทรต้องเป็นตัวเลข 10 หลัก ขึ้นต้นด้วย 0';

  /// เปิดหน้าสมัครจากหน้าเริ่มต้น เหมือนในแอปจริง (ปุ่มย้อนกลับจะได้มีที่ไป)
  Future<FakeServices> openRegister(WidgetTester tester, FakeBackend backend) async {
    usePhoneScreen(tester);
    final services = FakeServices(backend);
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => RegisterScreen(services: services)),
              ),
              child: const Text('start page'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('start page'));
    await tester.pumpAndSettle();
    return services;
  }

  Future<void> fill(
    WidgetTester tester, {
    String username = 'somchai',
    String phone = '0812345678',
    String password = 'Passw0rd!',
    String? confirm,
  }) async {
    await tester.enterText(fieldAt(0), username);
    await tester.enterText(fieldAt(1), phone);
    await tester.enterText(fieldAt(2), password);
    await tester.enterText(fieldAt(3), confirm ?? password);
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(submitButton());
    await tester.pumpAndSettle();
  }

  Future<http.Response> ok(http.Request request) async => json({'message': 'สมัครสมาชิกสำเร็จ', 'id': 30}, 201);

  testWidgets('REG-01 แสดงปุ่มเลือกประเภท 4 ช่องกรอก และปุ่มสมัคร', (tester) async {
    await openRegister(tester, ok);
    expect(find.text('สร้างบัญชีผู้ใช้'), findsOneWidget);
    expect(find.text('นักศึกษา'), findsOneWidget);
    expect(find.text('เจ้าของหอพัก'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(submitButton(), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'เข้าสู่ระบบ'), findsOneWidget);
  });

  testWidgets('REG-02 ฟอร์มว่างแสดง error เบอร์และรหัสผ่าน (ชื่อผู้ใช้ไม่บังคับ) และไม่ส่งอะไรไป', (tester) async {
    final services = await openRegister(tester, ok);
    await submit(tester);
    expect(find.text('กรุณากรอกเบอร์โทรศัพท์'), findsOneWidget);
    expect(find.text('รหัสผ่านต้องยาวอย่างน้อย 8 ตัว'), findsOneWidget);
    expect(find.textContaining('ชื่อผู้ใช้ต้อง'), findsNothing);
    expect(services.requests, isEmpty);
  });

  testWidgets('REG-03 เบอร์ผิดรูปแบบถูกปฏิเสธ', (tester) async {
    final services = await openRegister(tester, ok);
    for (final bad in ['12345', '1812345678', '081234567', '08123456789', 'abcdefghij']) {
      await fill(tester, phone: bad);
      await tester.tap(submitButton());
      await tester.pump();
      expect(find.text(phoneError), findsOneWidget, reason: 'เบอร์ "$bad" ควรไม่ผ่าน');
    }
    expect(services.requests, isEmpty);
  });

  testWidgets('REG-04 เบอร์แบบ +66 ผ่าน', (tester) async {
    final services = await openRegister(tester, ok);
    await fill(tester, phone: '+66812345678');
    await tester.tap(submitButton());
    await tester.pump();
    expect(find.text(phoneError), findsNothing);
    await tester.pumpAndSettle();
    expect(services.to('/api/auth/register'), hasLength(1));
  });

  testWidgets('REG-05 รหัสผ่าน 7 ตัวไม่ผ่าน 8 ตัวผ่าน', (tester) async {
    final services = await openRegister(tester, ok);
    await fill(tester, password: '1234567');
    await submit(tester);
    expect(find.text('รหัสผ่านต้องยาวอย่างน้อย 8 ตัว'), findsOneWidget);
    expect(services.requests, isEmpty);

    await fill(tester, password: '12345678');
    await submit(tester);
    expect(find.text('รหัสผ่านต้องยาวอย่างน้อย 8 ตัว'), findsNothing);
    expect(services.to('/api/auth/register'), hasLength(1));
  });

  testWidgets('REG-06 รหัสยืนยันไม่ตรงแสดง error', (tester) async {
    final services = await openRegister(tester, ok);
    await fill(tester, password: 'Passw0rd!', confirm: 'Passw0rd?');
    await submit(tester);
    expect(find.text('รหัสผ่านไม่ตรงกัน'), findsOneWidget);
    expect(services.requests, isEmpty);
  });

  testWidgets('REG-07 ชื่อผู้ใช้ยาวเกิน 50 ตัวถูกปฏิเสธ', (tester) async {
    await openRegister(tester, ok);
    await fill(tester, username: 'a' * 51);
    await submit(tester);
    expect(find.text('ชื่อผู้ใช้ต้องไม่เกิน 50 ตัวอักษร'), findsOneWidget);
  });

  testWidgets('REG-08 ช่องรหัสผ่านทั้งสองถูกซ่อน', (tester) async {
    await openRegister(tester, ok);
    expect(textFieldAt(tester, 2).obscureText, isTrue);
    expect(textFieldAt(tester, 3).obscureText, isTrue);
  });

  testWidgets('REG-09 สมัครเป็นนักศึกษา ส่งข้อมูลครบและ role = student', (tester) async {
    final services = await openRegister(tester, ok);
    await fill(tester, username: '  somchai ', phone: ' 0812345678 ');
    await submit(tester);
    expect(services.bodyOf('/api/auth/register'), {
      'phone': '0812345678',
      'password': 'Passw0rd!',
      'confirmPassword': 'Passw0rd!',
      'username': 'somchai',
      'role': 'student',
    });
  });

  testWidgets('REG-10 เลือกเจ้าของหอพัก แสดงคำอธิบาย และส่ง role = owner', (tester) async {
    final services = await openRegister(tester, ok);
    expect(find.textContaining('เอกสารแสดงความเป็นเจ้าของ'), findsNothing);
    await tester.tap(find.text('เจ้าของหอพัก'));
    await tester.pump();
    expect(find.textContaining('เอกสารแสดงความเป็นเจ้าของ'), findsOneWidget);

    await fill(tester);
    await submit(tester);
    expect(services.bodyOf('/api/auth/register')['role'], 'owner');
  });

  testWidgets('REG-11 ไม่กรอกชื่อผู้ใช้ ไม่ส่ง username', (tester) async {
    final services = await openRegister(tester, ok);
    await fill(tester, username: '');
    await submit(tester);
    expect(services.bodyOf('/api/auth/register').containsKey('username'), isFalse);
  });

  testWidgets('REG-12 สมัครสำเร็จ แสดง dialog แล้วกด "ตกลง" กลับหน้าก่อนหน้า', (tester) async {
    await openRegister(tester, ok);
    await fill(tester);
    await submit(tester);
    expect(find.text('สมัครสมาชิกสำเร็จ'), findsOneWidget);

    await tester.tap(find.text('ตกลง'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsNothing);
    expect(find.text('start page'), findsOneWidget);
  });

  testWidgets('REG-13 เบอร์ซ้ำ (409) แสดงข้อความใต้ฟอร์ม', (tester) async {
    await openRegister(tester, (request) async => json({'message': 'เบอร์นี้ถูกใช้แล้ว'}, 409));
    await fill(tester);
    await submit(tester);
    expect(find.text(RegisterController.duplicatePhoneMessage), findsOneWidget);
    expect(find.text('สมัครสมาชิกสำเร็จ'), findsNothing);
    expect(find.byType(RegisterScreen), findsOneWidget);
  });

  testWidgets('REG-14 server error (500) แสดงข้อความจาก server', (tester) async {
    await openRegister(tester, (request) async => json({'message': 'Database is down'}, 500));
    await fill(tester);
    await submit(tester);
    expect(find.text('Database is down'), findsOneWidget);
    expect(find.byType(RegisterScreen), findsOneWidget);
  });

  testWidgets('REG-15 server ไม่ได้เปิด แสดงข้อความเชื่อมต่อไม่ได้', (tester) async {
    await openRegister(tester, (request) async => throw Exception('connection refused'));
    await fill(tester);
    await submit(tester);
    expect(find.textContaining('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้'), findsOneWidget);
  });

  testWidgets('REG-16 ลิงก์ "เข้าสู่ระบบ" และปุ่มลูกศรย้อนกลับ กลับหน้าก่อนหน้า', (tester) async {
    await openRegister(tester, ok);
    await tester.tap(find.widgetWithText(TextButton, 'เข้าสู่ระบบ'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsNothing);

    await tester.tap(find.text('start page'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsNothing);
  });
}
