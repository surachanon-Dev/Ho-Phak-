// ผู้รับผิดชอบ: Plub (Tester)
// ทดสอบหน้า: เข้าสู่ระบบ (lib/features/auth/login/login_screen.dart)
// ใช้ backend จำลอง (MockClient) จึงไม่ต้องเปิด server
// Run: flutter test test/widgets/login_screen_test.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/auth/login/login_controller.dart';
import 'package:hopak_frontend/features/auth/login/login_screen.dart';
import 'package:hopak_frontend/features/auth/register/register_screen.dart';
import 'package:hopak_frontend/features/student/student_shell.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_services.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ลำดับช่องในหน้า: 0 ชื่อผู้ใช้/เบอร์, 1 รหัสผ่าน
  Finder loginButton() => find.widgetWithText(FilledButton, 'เข้าสู่ระบบ');

  Future<FakeServices> openLogin(WidgetTester tester, FakeBackend backend) async {
    usePhoneScreen(tester);
    final services = FakeServices(backend);
    await tester.pumpWidget(MaterialApp(home: LoginScreen(services: services)));
    return services;
  }

  Future<void> signIn(WidgetTester tester, String id, String password) async {
    await tester.enterText(fieldAt(0), id);
    await tester.enterText(fieldAt(1), password);
    await tester.tap(loginButton());
    await tester.pumpAndSettle();
  }

  /// Backend ที่ login ผ่านเสมอ ได้บัญชี [role]
  FakeBackend backend({String role = 'student', String status = 'active'}) => (request) async {
    switch (request.url.path) {
      case '/api/login':
        return json({'token': 'test-jwt', 'user': me(role: role)['user']});
      case '/api/me':
        return json(me(role: role, status: status));
      case '/api/auth/register':
        return json({'message': 'สมัครสมาชิกสำเร็จ', 'id': 30}, 201);
      default:
        return emptyAnswer(request);
    }
  };

  testWidgets('LOGIN-01 แสดงโลโก้ ช่องชื่อผู้ใช้/เบอร์ ช่องรหัสผ่าน ปุ่มเข้าสู่ระบบ และลิงก์สมัคร', (tester) async {
    await openLogin(tester, backend());
    expect(find.text('Ho-Phak'), findsOneWidget);
    expect(find.text('ยินดีต้อนรับกลับมา'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(loginButton(), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'สมัครสมาชิก'), findsOneWidget);
  });

  testWidgets('LOGIN-02 ฟอร์มว่างแสดง error ทั้งสองช่อง และไม่ส่งอะไรไป server', (tester) async {
    final services = await openLogin(tester, backend());
    await tester.tap(loginButton());
    await tester.pump();
    expect(find.text('กรุณากรอกชื่อผู้ใช้หรือเบอร์โทร'), findsOneWidget);
    expect(find.text('กรุณากรอกรหัสผ่าน'), findsOneWidget);
    expect(services.requests, isEmpty);
  });

  testWidgets('LOGIN-03 กรอกแต่ช่องว่างถือว่ายังไม่กรอก', (tester) async {
    final services = await openLogin(tester, backend());
    await tester.enterText(fieldAt(0), '   ');
    await tester.enterText(fieldAt(1), 'Passw0rd!');
    await tester.tap(loginButton());
    await tester.pump();
    expect(find.text('กรุณากรอกชื่อผู้ใช้หรือเบอร์โทร'), findsOneWidget);
    expect(services.requests, isEmpty);
  });

  testWidgets('LOGIN-04 รหัสผ่านถูกซ่อน กดรูปตาแล้วเห็นรหัส', (tester) async {
    await openLogin(tester, backend());
    expect(textFieldAt(tester, 1).obscureText, isTrue);
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();
    expect(textFieldAt(tester, 1).obscureText, isFalse);
  });

  testWidgets('LOGIN-05 รหัสผิด (401) แสดงข้อความใต้ฟอร์ม และยังอยู่หน้าเดิม', (tester) async {
    final services = await openLogin(tester, (request) async => json({'message': 'x'}, 401));
    await signIn(tester, '0812345678', 'wrong-password');
    expect(find.text(LoginController.invalidCredentialsMessage), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(services.tokens.token, isNull);
  });

  testWidgets('LOGIN-06 กรอกเบอร์ ส่งเป็น phone (ตัดช่องว่างหน้า-หลัง) และส่งรหัสตามที่พิมพ์', (tester) async {
    final services = await openLogin(tester, (request) async => json({'message': 'x'}, 401));
    await signIn(tester, '  0812345678  ', ' Passw0rd! ');
    expect(services.bodyOf('/api/login'), {'phone': '0812345678', 'password': ' Passw0rd! '});
  });

  testWidgets('LOGIN-07 กรอกชื่อผู้ใช้ ส่งเป็น username', (tester) async {
    final services = await openLogin(tester, (request) async => json({'message': 'x'}, 401));
    await signIn(tester, 'somchai', 'Passw0rd!');
    expect(services.bodyOf('/api/login'), {'username': 'somchai', 'password': 'Passw0rd!'});
  });

  testWidgets('LOGIN-08 login สำเร็จ เก็บ token และเข้าหน้านักศึกษา', (tester) async {
    final services = await openLogin(tester, backend(role: 'student'));
    // จอกว้างขึ้น: font ในเทสต์กว้างกว่าภาษาไทยจริงมาก ข้อนี้ทดสอบการ login ไม่ใช่ layout หน้านักศึกษา
    tester.view.physicalSize = const Size(1080, 1400);
    await tester.pump();
    await signIn(tester, '0812345678', 'Passw0rd!');
    expect(services.tokens.token, 'test-jwt');
    expect(services.to('/api/me').first.headers['Authorization'], 'Bearer test-jwt');
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(StudentShell), findsOneWidget);
  });

  testWidgets('LOGIN-09 บัญชีถูกระงับ ถูก logout และเห็นข้อความ', (tester) async {
    final services = await openLogin(tester, backend(status: 'suspended'));
    await signIn(tester, '0812345678', 'Passw0rd!');
    expect(find.text('บัญชีนี้ถูกระงับ ติดต่อแอดมิน'), findsOneWidget);
    expect(services.tokens.token, isNull);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('LOGIN-10 server ไม่ได้เปิด แสดงข้อความเชื่อมต่อไม่ได้', (tester) async {
    await openLogin(tester, (request) async => throw Exception('connection refused'));
    await signIn(tester, '0812345678', 'Passw0rd!');
    expect(find.textContaining('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้'), findsOneWidget);
  });

  testWidgets('LOGIN-11 server error (500) แสดงข้อความจาก server', (tester) async {
    await openLogin(tester, (request) async => json({'message': 'Database is down'}, 500));
    await signIn(tester, '0812345678', 'Passw0rd!');
    expect(find.text('Database is down'), findsOneWidget);
  });

  testWidgets('LOGIN-12 ระหว่างรอ ปุ่มกดไม่ได้และมี spinner (กดซ้ำไม่ได้)', (tester) async {
    final answer = Completer<http.Response>();
    final services = await openLogin(tester, (request) => answer.future);
    await tester.enterText(fieldAt(0), '0812345678');
    await tester.enterText(fieldAt(1), 'Passw0rd!');
    await tester.tap(loginButton());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(services.to('/api/login'), hasLength(1));

    answer.complete(json({'message': 'x'}, 401));
    await tester.pumpAndSettle();
    expect(loginButton(), findsOneWidget);
  });

  testWidgets('LOGIN-13 กด "สมัครสมาชิก" เปิดหน้าสมัคร', (tester) async {
    await openLogin(tester, backend());
    await tester.tap(find.widgetWithText(TextButton, 'สมัครสมาชิก'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);
  });

  testWidgets('LOGIN-14 สมัครเสร็จแล้วกลับมา ช่องเบอร์ถูกเติมให้', (tester) async {
    await openLogin(tester, backend());
    await tester.tap(find.widgetWithText(TextButton, 'สมัครสมาชิก'));
    await tester.pumpAndSettle();

    // หน้าสมัคร: 0 ชื่อผู้ใช้, 1 เบอร์, 2 รหัสผ่าน, 3 ยืนยัน
    await tester.enterText(fieldAt(1), '0812345678');
    await tester.enterText(fieldAt(2), 'Passw0rd!');
    await tester.enterText(fieldAt(3), 'Passw0rd!');
    await tester.tap(find.widgetWithText(FilledButton, 'สมัครสมาชิก'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ตกลง'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(textFieldAt(tester, 0).controller?.text, '0812345678');
  });
}
