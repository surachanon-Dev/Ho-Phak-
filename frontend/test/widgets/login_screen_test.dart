// ผู้รับผิดชอบ: Plub (Tester)
// ทดสอบหน้า: เข้าสู่ระบบ (login)
// Widget Test: Sign In page (lib/features/auth/login/login_screen.dart)
// Uses a fake backend (MockClient), so the real server does not need to run.
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

  // Field order on the page: 0 phone, 1 password
  Future<FakeServices> openLogin(WidgetTester tester, FakeBackend backend) async {
    usePhoneScreen(tester);
    final services = FakeServices(backend);
    await tester.pumpWidget(MaterialApp(home: LoginScreen(services: services)));
    return services;
  }

  Future<void> signIn(WidgetTester tester, String phone, String password) async {
    await tester.enterText(fieldAt(0), phone);
    await tester.enterText(fieldAt(1), password);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
    await tester.pumpAndSettle();
  }

  /// Backend where 0812345678 / Passw0rd! is a valid account with [role]
  FakeBackend backend({String role = 'student', String status = 'active'}) => (request) async {
    switch (request.url.path) {
      case '/api/login':
        return json({'token': 'test-jwt', 'user': me(role: role)['user']});
      case '/api/me':
        return json(me(role: role, status: status));
      default:
        return emptyAnswer(request);
    }
  };

  testWidgets('LOGIN-01 shows phone field, password field, Sign In and Sign Up link', (tester) async {
    await openLogin(tester, backend());
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.widgetWithText(FilledButton, 'Sign In'), findsOneWidget);
    expect(find.text('New here? Sign Up'), findsOneWidget);
  });

  testWidgets('LOGIN-02 empty form shows both errors and sends nothing', (tester) async {
    final services = await openLogin(tester, backend());
    await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
    await tester.pump();
    expect(find.text('กรุณากรอกเบอร์โทรศัพท์'), findsOneWidget);
    expect(find.text('กรุณากรอกรหัสผ่าน'), findsOneWidget);
    expect(services.requests, isEmpty);
  });

  testWidgets('LOGIN-03 a phone with only spaces is treated as empty', (tester) async {
    final services = await openLogin(tester, backend());
    await tester.enterText(fieldAt(0), '   ');
    await tester.enterText(fieldAt(1), 'Passw0rd!');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
    await tester.pump();
    expect(find.text('กรุณากรอกเบอร์โทรศัพท์'), findsOneWidget);
    expect(services.requests, isEmpty);
  });

  testWidgets('LOGIN-04 password is hidden', (tester) async {
    await openLogin(tester, backend());
    expect(textFieldAt(tester, 1).obscureText, isTrue);
    expect(textFieldAt(tester, 0).obscureText, isFalse);
  });

  testWidgets('LOGIN-05 wrong password (401) shows the message under the form and stays on Sign In', (tester) async {
    final services = await openLogin(tester, (request) async => json({'message': 'Invalid credentials'}, 401));
    await signIn(tester, '0812345678', 'wrong-password');
    expect(find.text(LoginController.invalidCredentialsMessage), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(services.tokens.token, isNull);
  });

  testWidgets('LOGIN-06 sends the phone without spaces and the password as typed', (tester) async {
    final services = await openLogin(tester, (request) async => json({'message': 'x'}, 401));
    await signIn(tester, '  0812345678  ', ' Passw0rd! ');
    expect(services.bodyOf('/api/login'), {'phone': '0812345678', 'password': ' Passw0rd! '});
  });

  testWidgets('LOGIN-07 correct login saves the token and opens the student area', (tester) async {
    final services = await openLogin(tester, backend(role: 'student'));
    // Wider screen: the test font is much wider than real Thai text, and this test is about login,
    // not the student home layout (that overflow is reported separately as a UI bug)
    tester.view.physicalSize = const Size(1080, 1400);
    await tester.pump();
    await signIn(tester, '0812345678', 'Passw0rd!');
    expect(services.tokens.token, 'test-jwt');
    expect(services.to('/api/me').first.headers['Authorization'], 'Bearer test-jwt');
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(StudentShell), findsOneWidget);
  });

  testWidgets('LOGIN-08 suspended account is logged out and sees the reason', (tester) async {
    final services = await openLogin(tester, backend(status: 'suspended'));
    await signIn(tester, '0812345678', 'Passw0rd!');
    expect(find.text('บัญชีนี้ถูกระงับ ติดต่อแอดมิน'), findsOneWidget);
    expect(services.to('/api/auth/logout'), hasLength(1));
    expect(services.tokens.token, isNull);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('LOGIN-09 server not running shows the connection error', (tester) async {
    await openLogin(tester, (request) async => throw Exception('connection refused'));
    await signIn(tester, '0812345678', 'Passw0rd!');
    expect(find.textContaining('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('LOGIN-10 server error (500) shows the message from the server', (tester) async {
    await openLogin(tester, (request) async => json({'message': 'Database is down'}, 500));
    await signIn(tester, '0812345678', 'Passw0rd!');
    expect(find.text('Database is down'), findsOneWidget);
  });

  testWidgets('LOGIN-11 button is disabled and shows a spinner while waiting (no double submit)', (tester) async {
    final answer = Completer<http.Response>();
    final services = await openLogin(tester, (request) => answer.future);
    await tester.enterText(fieldAt(0), '0812345678');
    await tester.enterText(fieldAt(1), 'Passw0rd!');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(services.to('/api/login'), hasLength(1));

    answer.complete(json({'message': 'x'}, 401));
    await tester.pumpAndSettle();
    expect(find.text('Sign In'), findsWidgets);
  });

  testWidgets('LOGIN-12 "New here? Sign Up" opens the Sign Up page', (tester) async {
    await openLogin(tester, backend());
    await tester.tap(find.text('New here? Sign Up'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);
  });
}
