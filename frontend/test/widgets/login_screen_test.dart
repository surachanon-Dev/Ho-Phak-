// ผู้รับผิดชอบ: Plub (Tester)
// ทดสอบหน้า: เข้าสู่ระบบ (lib/modules/auth/login/view/login_screen.dart)
// ใช้ backend ปลอมของทีม (test/helpers/fake_backend.dart) จึงไม่ต้องเปิด server
// Run: flutter test test/widgets/login_screen_test.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/modules/auth/forgot_password/view/forgot_password_screen.dart';
import 'package:hopak_frontend/modules/auth/login/controller/login_controller.dart';
import 'package:hopak_frontend/modules/auth/login/view/login_screen.dart';
import 'package:hopak_frontend/modules/auth/register/view/register_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_backend.dart';

/// ข้อมูลที่ backend ตอบเมื่อ login ผ่าน
Map<String, Object> loggedIn({String role = 'student', String status = 'active'}) => {
  'POST /api/login': {'token': 'test-jwt'},
  'GET /api/me': {
    'user': {'id': 9, 'username': 'karn', 'role': role, 'status': status, 'is_verified': 0},
  },
  'POST /api/auth/logout': {'ok': true},
  'GET /api/dormitories': {'dormitories': []},
  'GET /api/conversations': {'conversations': []},
  'GET /api/notifications': {'notifications': []},
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ลำดับช่องในหน้า: 0 ชื่อผู้ใช้/เบอร์, 1 รหัสผ่าน
  Finder field(int i) => find.byType(TextFormField).at(i);
  Finder loginButton() => find.widgetWithText(FilledButton, 'เข้าสู่ระบบ');
  TextField textField(WidgetTester t, int i) =>
      t.widget<TextField>(find.descendant(of: field(i), matching: find.byType(TextField)));

  Future<FakeServices> open(WidgetTester tester, Map<String, Object> routes, List<http.Request> requests) async {
    useDesktopScreen(tester);
    tester.view.physicalSize = const Size(1200, 1800);
    final services = fakeBackend(routes, requests: requests);
    await tester.pumpWidget(MaterialApp(home: LoginScreen(services: services)));
    await tester.pumpAndSettle();
    return services;
  }

  Future<void> signIn(WidgetTester tester, String id, String password) async {
    await tester.enterText(field(0), id);
    await tester.enterText(field(1), password);
    await tester.tap(loginButton());
    await tester.pumpAndSettle();
  }

  Map<String, dynamic> loginBody(List<http.Request> requests) =>
      jsonDecode(requests.lastWhere((r) => r.url.path == '/api/login').body) as Map<String, dynamic>;

  testWidgets('LOGIN-01 แสดงโลโก้ หัวข้อ 2 ช่องกรอก ปุ่มเข้าสู่ระบบ ลืมรหัสผ่าน และลิงก์สมัคร', (tester) async {
    await open(tester, {}, []);
    expect(find.text('Ho-Phak'), findsOneWidget);
    expect(find.text('ยินดีต้อนรับกลับมา'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(loginButton(), findsOneWidget);
    expect(find.text('ลืมรหัสผ่าน?'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'สมัครสมาชิก'), findsOneWidget);
  });

  testWidgets('LOGIN-02 ฟอร์มว่างแสดง error ทั้งสองช่อง และไม่ส่งอะไรไป', (tester) async {
    final requests = <http.Request>[];
    await open(tester, {}, requests);
    await tester.tap(loginButton());
    await tester.pump();
    expect(find.text('กรุณากรอกชื่อผู้ใช้หรือเบอร์โทร'), findsOneWidget);
    expect(find.text('กรุณากรอกรหัสผ่าน'), findsOneWidget);
    expect(requests, isEmpty);
  });

  testWidgets('LOGIN-03 กรอกแต่ช่องว่างถือว่ายังไม่กรอก', (tester) async {
    final requests = <http.Request>[];
    await open(tester, {}, requests);
    await tester.enterText(field(0), '   ');
    await tester.enterText(field(1), 'secret123');
    await tester.tap(loginButton());
    await tester.pump();
    expect(find.text('กรุณากรอกชื่อผู้ใช้หรือเบอร์โทร'), findsOneWidget);
    expect(requests, isEmpty);
  });

  testWidgets('LOGIN-04 รหัสผ่านถูกซ่อน กดรูปตาแล้วเห็นรหัส', (tester) async {
    await open(tester, {}, []);
    expect(textField(tester, 1).obscureText, isTrue);
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();
    expect(textField(tester, 1).obscureText, isFalse);
  });

  testWidgets('LOGIN-05 รหัสผิด (401) แสดงข้อความใต้ฟอร์ม และยังอยู่หน้าเดิม', (tester) async {
    final services = await open(tester, {'POST /api/login': http.Response('{"message":"Invalid"}', 401)}, []);
    await signIn(tester, '0812345678', 'wrong');
    expect(find.text(LoginController.invalidCredentialsMessage), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(services.tokens.token, isNull);
  });

  testWidgets('LOGIN-06 กรอกเบอร์ ส่งเป็น phone (ตัดช่องว่าง) รหัสส่งตามที่พิมพ์', (tester) async {
    final requests = <http.Request>[];
    await open(tester, {'POST /api/login': http.Response('{"message":"x"}', 401)}, requests);
    await signIn(tester, '  0812345678  ', ' secret123 ');
    expect(loginBody(requests), {'phone': '0812345678', 'password': ' secret123 '});
  });

  testWidgets('LOGIN-07 กรอกชื่อผู้ใช้ ส่งเป็น username', (tester) async {
    final requests = <http.Request>[];
    await open(tester, {'POST /api/login': http.Response('{"message":"x"}', 401)}, requests);
    await signIn(tester, 'karn', 'secret123');
    expect(loginBody(requests), {'username': 'karn', 'password': 'secret123'});
  });

  testWidgets('LOGIN-08 login สำเร็จ เก็บ token แนบ token ตอนเรียก /api/me และออกจากหน้า login', (tester) async {
    final requests = <http.Request>[];
    final services = await open(tester, loggedIn(), requests);
    await signIn(tester, '0812345678', 'secret123');
    expect(services.tokens.token, 'test-jwt');
    final me = requests.firstWhere((r) => r.url.path == '/api/me');
    expect(me.headers['Authorization'], 'Bearer test-jwt');
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.text('Hello, karn'), findsOneWidget);
  });

  testWidgets('LOGIN-09 บัญชีถูกระงับ ถูก logout และเห็นข้อความ', (tester) async {
    final requests = <http.Request>[];
    final services = await open(tester, loggedIn(status: 'suspended'), requests);
    await signIn(tester, '0812345678', 'secret123');
    expect(find.text('บัญชีนี้ถูกระงับ กรุณาติดต่อผู้ดูแลระบบ'), findsOneWidget);
    expect(requests.where((r) => r.url.path == '/api/auth/logout'), hasLength(1));
    expect(services.tokens.token, isNull);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('LOGIN-10 server error (500) แสดงข้อความจาก server', (tester) async {
    await open(tester, {'POST /api/login': http.Response('{"message":"Database is down"}', 500)}, []);
    await signIn(tester, '0812345678', 'secret123');
    expect(find.text('Database is down'), findsOneWidget);
  });

  testWidgets('LOGIN-11 ลิงก์ "สมัครสมาชิก" เปิดหน้าสมัคร', (tester) async {
    await open(tester, {}, []);
    await tester.tap(find.widgetWithText(TextButton, 'สมัครสมาชิก'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);
  });

  testWidgets('LOGIN-12 ลิงก์ "ลืมรหัสผ่าน?" เปิดหน้าลืมรหัสผ่าน', (tester) async {
    await open(tester, {}, []);
    await tester.tap(find.text('ลืมรหัสผ่าน?'));
    await tester.pumpAndSettle();
    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
  });

  testWidgets('LOGIN-13 สมัครเสร็จแล้วกลับมา ช่องเบอร์ถูกเติมให้', (tester) async {
    await open(tester, {'POST /api/auth/register': {'ok': true}}, []);
    await tester.tap(find.widgetWithText(TextButton, 'สมัครสมาชิก'));
    await tester.pumpAndSettle();

    // หน้าสมัคร: 0 ชื่อผู้ใช้, 1 เบอร์, 2 รหัสผ่าน, 3 ยืนยัน
    await tester.enterText(field(1), '0812345678');
    await tester.enterText(field(2), 'secret123');
    await tester.enterText(field(3), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'สมัครสมาชิก'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ตกลง'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(textField(tester, 0).controller?.text, '0812345678');
  });
}
