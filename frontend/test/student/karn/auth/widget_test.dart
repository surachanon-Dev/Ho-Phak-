// ผู้รับผิดชอบ: Karn (นักศึกษา)
// widget test: หน้าต้อนรับ, เข้าสู่ระบบ, สมัครสมาชิก และลืมรหัสผ่าน
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/modules/auth/login/view/login_screen.dart';
import 'package:hopak_frontend/modules/auth/register/view/register_screen.dart';
import 'package:hopak_frontend/modules/auth/welcome/view/welcome_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_backend.dart';

Future<void> open(WidgetTester tester, Widget page) async {
  useDesktopScreen(tester);
  tester.view.physicalSize = const Size(1200, 1800); // ฟอร์มยาว ไม่ต้องเลื่อน
  await tester.pumpWidget(MaterialApp(home: page));
  await tester.pumpAndSettle();
}

Future<void> fillLogin(
  WidgetTester tester,
  String phone,
  String password,
) async {
  await tester.enterText(find.byType(TextFormField).at(0), phone);
  await tester.enterText(find.byType(TextFormField).at(1), password);
  await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
  await tester.pumpAndSettle();
}

/// กรอกฟอร์มสมัคร: ชื่อ, นามสกุล, เบอร์, รหัสผ่าน, ยืนยันรหัสผ่าน
Future<void> fillRegister(WidgetTester tester, String confirm) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'Karn');
  await tester.enterText(fields.at(1), 'Student');
  await tester.enterText(fields.at(2), '0812345678');
  await tester.enterText(fields.at(3), 'secret123');
  await tester.enterText(fields.at(4), confirm);
  await tester.tap(find.widgetWithText(FilledButton, 'Sign Up'));
  await tester.pumpAndSettle();
}

LoginScreen login(AppServices services) => LoginScreen(services: services);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('1. Welcome page shows the app name and opens Sign In', (
    tester,
  ) async {
    await open(tester, WelcomeScreen(services: fakeBackend({})));
    expect(find.text('Welcome to Ho-Phak'), findsOneWidget);

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in with your phone number'), findsOneWidget);
  });

  testWidgets('2. Empty sign-in form shows what is missing', (tester) async {
    final requests = <http.Request>[];
    await open(tester, login(fakeBackend({}, requests: requests)));

    await fillLogin(tester, '', '');

    expect(find.text('Please enter your phone number'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
    expect(requests, isEmpty);
  });

  testWidgets('3. Wrong password shows a message under the form', (
    tester,
  ) async {
    await open(
      tester,
      login(
        fakeBackend({
          'POST /api/login': http.Response('{"message":"Invalid"}', 401),
        }),
      ),
    );

    await fillLogin(tester, '0812345678', 'wrong');

    expect(
      find.text('Wrong phone number or password. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('4. Correct sign-in opens the student home page', (tester) async {
    final requests = <http.Request>[];
    await open(
      tester,
      login(
        fakeBackend({
          'POST /api/login': {'token': 'test-token'},
          'GET /api/me': {
            'user': {
              'id': 9,
              'username': 'karn',
              'role': 'student',
              'status': 'active',
              'is_verified': 0,
            },
          },
          'GET /api/dormitories': {'dormitories': []},
          'GET /api/conversations': {'conversations': []},
          'GET /api/notifications': {'notifications': []},
        }, requests: requests),
      ),
    );

    await fillLogin(tester, ' 0812345678 ', 'secret123');

    final post = requests.firstWhere((r) => r.url.path == '/api/login');
    expect(jsonDecode(post.body), {
      'phone': '0812345678',
      'password': 'secret123',
    });
    expect(find.text('Hello, karn'), findsOneWidget);
  });

  testWidgets('5. Sign Up link opens the register page', (tester) async {
    await open(tester, login(fakeBackend({})));

    await tester.tap(find.text('New here? Sign Up'));
    await tester.pumpAndSettle();

    expect(find.text('Create a new account'), findsOneWidget);
  });

  testWidgets('6. Passwords that do not match are not sent', (tester) async {
    final requests = <http.Request>[];
    await open(
      tester,
      RegisterScreen(services: fakeBackend({}, requests: requests)),
    );

    await fillRegister(tester, 'different1');

    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(requests, isEmpty);
  });

  testWidgets('7. Successful sign up sends the form and says it is done', (
    tester,
  ) async {
    final requests = <http.Request>[];
    await open(
      tester,
      RegisterScreen(
        services: fakeBackend({
          'POST /api/auth/register': {'ok': true},
        }, requests: requests),
      ),
    );

    await fillRegister(tester, 'secret123');

    expect(jsonDecode(requests.single.body), {
      'phone': '0812345678',
      'password': 'secret123',
      'confirmPassword': 'secret123',
      'first_name': 'Karn',
      'surname': 'Student',
    });
    expect(find.text('Sign up complete'), findsOneWidget);
  });

  testWidgets('8. Forgot password link explains how to reset', (tester) async {
    await open(tester, login(fakeBackend({})));

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.text('Reset your password'), findsOneWidget);
    expect(find.text('1. Contact an admin'), findsOneWidget);
  });
}
