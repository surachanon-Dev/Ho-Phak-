// ผู้รับผิดชอบ: Plub (Tester)
// ทดสอบหน้า: สมัครสมาชิก (lib/modules/auth/register/view/register_screen.dart)
// ใช้ backend ปลอมของทีม (test/helpers/fake_backend.dart) จึงไม่ต้องเปิด server
// Run: flutter test test/widgets/register_screen_test.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/modules/auth/register/controller/register_controller.dart';
import 'package:hopak_frontend/modules/auth/register/view/register_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_backend.dart';

const ok = {'POST /api/auth/register': {'message': 'สมัครสมาชิกสำเร็จ', 'id': 30}};

/// backend ที่รองรับการสมัครแล้วเปลี่ยนเป็นเจ้าของหอ
final ownerFlow = <String, Object>{
  ...ok,
  'POST /api/login': {'token': 'tmp-jwt'},
  'GET /api/me': {
    'user': {'id': 30, 'username': 'owner1', 'role': 'student', 'status': 'active', 'is_verified': 0},
  },
  'POST /api/me/become-owner': {'ok': true},
  'POST /api/auth/logout': {'ok': true},
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ลำดับช่องในหน้า: 0 ชื่อผู้ใช้, 1 เบอร์, 2 รหัสผ่าน, 3 ยืนยันรหัสผ่าน
  Finder field(int i) => find.byType(TextFormField).at(i);
  Finder submitButton() => find.widgetWithText(FilledButton, 'สมัครสมาชิก');
  const phoneError = 'เบอร์โทรต้องเป็นตัวเลข 10 หลัก ขึ้นต้นด้วย 0';

  List<String> calls(List<http.Request> r) => r.map((x) => '${x.method} ${x.url.path}').toList();
  Map<String, dynamic> registerBody(List<http.Request> r) =>
      jsonDecode(r.firstWhere((x) => x.url.path == '/api/auth/register').body) as Map<String, dynamic>;

  /// เปิดหน้าสมัครจากหน้าเริ่มต้น เหมือนในแอปจริง (ปุ่มย้อนกลับจะได้มีที่ไป)
  Future<FakeServices> open(WidgetTester tester, Map<String, Object> routes, List<http.Request> requests) async {
    useDesktopScreen(tester);
    tester.view.physicalSize = const Size(1200, 1800);
    final services = fakeBackend(routes, requests: requests);
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
    String password = 'secret123',
    String? confirm,
  }) async {
    await tester.enterText(field(0), username);
    await tester.enterText(field(1), phone);
    await tester.enterText(field(2), password);
    await tester.enterText(field(3), confirm ?? password);
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(submitButton());
    await tester.pumpAndSettle();
  }

  testWidgets('REG-01 แสดงปุ่มเลือกประเภท 4 ช่องกรอก ปุ่มสมัคร และลิงก์เข้าสู่ระบบ', (tester) async {
    await open(tester, ok, []);
    expect(find.text('สร้างบัญชีผู้ใช้'), findsOneWidget);
    expect(find.text('นักศึกษา'), findsOneWidget);
    expect(find.text('เจ้าของหอพัก'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(submitButton(), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'เข้าสู่ระบบ'), findsOneWidget);
  });

  testWidgets('REG-02 ฟอร์มว่างแสดง error เบอร์และรหัสผ่าน (ชื่อผู้ใช้ไม่บังคับ) และไม่ส่งอะไรไป', (tester) async {
    final requests = <http.Request>[];
    await open(tester, ok, requests);
    await submit(tester);
    expect(find.text('กรุณากรอกเบอร์โทรศัพท์'), findsOneWidget);
    expect(find.text('รหัสผ่านต้องยาวอย่างน้อย 8 ตัว'), findsOneWidget);
    expect(find.textContaining('ชื่อผู้ใช้ต้อง'), findsNothing);
    expect(requests, isEmpty);
  });

  testWidgets('REG-03 เบอร์ผิดรูปแบบถูกปฏิเสธ', (tester) async {
    final requests = <http.Request>[];
    await open(tester, ok, requests);
    for (final bad in ['12345', '1812345678', '081234567', '08123456789', 'abcdefghij']) {
      await fill(tester, phone: bad);
      await tester.tap(submitButton());
      await tester.pump();
      expect(find.text(phoneError), findsOneWidget, reason: 'เบอร์ "$bad" ควรไม่ผ่าน');
    }
    expect(requests, isEmpty);
  });

  testWidgets('REG-04 เบอร์แบบ +66 ผ่าน', (tester) async {
    final requests = <http.Request>[];
    await open(tester, ok, requests);
    await fill(tester, phone: '+66812345678');
    await submit(tester);
    expect(find.text(phoneError), findsNothing);
    expect(calls(requests), contains('POST /api/auth/register'));
  });

  testWidgets('REG-05 รหัสผ่าน 7 ตัวไม่ผ่าน 8 ตัวผ่าน', (tester) async {
    final requests = <http.Request>[];
    await open(tester, ok, requests);
    await fill(tester, password: '1234567');
    await submit(tester);
    expect(find.text('รหัสผ่านต้องยาวอย่างน้อย 8 ตัว'), findsOneWidget);
    expect(requests, isEmpty);

    await fill(tester, password: '12345678');
    await submit(tester);
    expect(calls(requests), ['POST /api/auth/register']);
  });

  testWidgets('REG-06 รหัสยืนยันไม่ตรงแสดง error', (tester) async {
    final requests = <http.Request>[];
    await open(tester, ok, requests);
    await fill(tester, password: 'secret123', confirm: 'secret124');
    await submit(tester);
    expect(find.text('รหัสผ่านไม่ตรงกัน'), findsOneWidget);
    expect(requests, isEmpty);
  });

  testWidgets('REG-07 ชื่อผู้ใช้ยาวเกิน 50 ตัวถูกปฏิเสธ', (tester) async {
    await open(tester, ok, []);
    await fill(tester, username: 'a' * 51);
    await submit(tester);
    expect(find.text('ชื่อผู้ใช้ต้องไม่เกิน 50 ตัวอักษร'), findsOneWidget);
  });

  testWidgets('REG-08 ช่องรหัสผ่านทั้งสองถูกซ่อน', (tester) async {
    await open(tester, ok, []);
    for (final i in [2, 3]) {
      final tf = tester.widget<TextField>(find.descendant(of: field(i), matching: find.byType(TextField)));
      expect(tf.obscureText, isTrue);
    }
  });

  testWidgets('REG-09 สมัครเป็นนักศึกษา ส่งข้อมูลที่ตัดช่องว่างแล้ว และไม่ส่ง role', (tester) async {
    final requests = <http.Request>[];
    await open(tester, ok, requests);
    await fill(tester, username: '  somchai ', phone: ' 0812345678 ');
    await submit(tester);
    expect(registerBody(requests), {
      'phone': '0812345678',
      'password': 'secret123',
      'confirmPassword': 'secret123',
      'username': 'somchai',
    });
    expect(calls(requests), ['POST /api/auth/register']);
  });

  testWidgets('REG-10 ไม่กรอกชื่อผู้ใช้ ไม่ส่ง username', (tester) async {
    final requests = <http.Request>[];
    await open(tester, ok, requests);
    await fill(tester, username: '');
    await submit(tester);
    expect(registerBody(requests).containsKey('username'), isFalse);
  });

  testWidgets('REG-11 เลือกเจ้าของหอพัก: สมัคร → login ชั่วคราว → become-owner → logout', (tester) async {
    final requests = <http.Request>[];
    final services = await open(tester, ownerFlow, requests);
    expect(find.textContaining('เอกสารแสดงความเป็นเจ้าของ'), findsNothing);
    await tester.tap(find.text('เจ้าของหอพัก'));
    await tester.pump();
    expect(find.textContaining('เอกสารแสดงความเป็นเจ้าของ'), findsOneWidget);

    await fill(tester);
    await submit(tester);
    expect(
      calls(requests),
      containsAllInOrder(['POST /api/auth/register', 'POST /api/login', 'POST /api/me/become-owner', 'POST /api/auth/logout']),
    );
    expect(services.tokens.token, isNull, reason: 'ต้อง logout หลังเปลี่ยนเป็นเจ้าของหอ');
    expect(find.textContaining('บัญชีเจ้าของหอพักพร้อมแล้ว'), findsOneWidget);
  });

  testWidgets('REG-12 สมัครสำเร็จ แสดง dialog แล้วกด "ตกลง" กลับหน้าก่อนหน้า', (tester) async {
    await open(tester, ok, []);
    await fill(tester);
    await submit(tester);
    expect(find.text('สมัครสมาชิกสำเร็จ'), findsOneWidget);

    await tester.tap(find.text('ตกลง'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsNothing);
    expect(find.text('start page'), findsOneWidget);
  });

  testWidgets('REG-13 เบอร์ซ้ำ (409) แสดงข้อความใต้ฟอร์ม', (tester) async {
    await open(tester, {
      // ข้อความไทยต้องส่งเป็น bytes UTF-8 (http.Response แบบ String รองรับแค่ latin1)
      'POST /api/auth/register': http.Response.bytes(utf8.encode(jsonEncode({'message': 'เบอร์นี้ถูกใช้แล้ว'})), 409),
    }, []);
    await fill(tester);
    await submit(tester);
    expect(find.text(RegisterController.duplicatePhoneMessage), findsOneWidget);
    expect(find.text('สมัครสมาชิกสำเร็จ'), findsNothing);
    expect(find.byType(RegisterScreen), findsOneWidget);
  });

  testWidgets('REG-14 server error (500) แสดงข้อความจาก server', (tester) async {
    await open(tester, {'POST /api/auth/register': http.Response('{"message":"Database is down"}', 500)}, []);
    await fill(tester);
    await submit(tester);
    expect(find.text('Database is down'), findsOneWidget);
    expect(find.byType(RegisterScreen), findsOneWidget);
  });

  testWidgets('REG-15 ลิงก์ "เข้าสู่ระบบ" และลูกศรย้อนกลับ กลับหน้าก่อนหน้า', (tester) async {
    await open(tester, ok, []);
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
