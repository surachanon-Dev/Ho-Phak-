// Widget Test: Sign Up page (lib/screens/register_screen.dart)
// Uses a fake backend (MockClient), so the real server does not need to run.
// Run: flutter test test/widgets/register_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/controller/auth/register_controller.dart';
import 'package:hopak_frontend/screens/register_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_services.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // Field order on the page: 0 first name, 1 surname, 2 phone, 3 password, 4 confirm
  Finder signUpButton() => find.widgetWithText(FilledButton, 'Sign Up');

  /// Opens Sign Up from a start page, like the real app (so "back" has somewhere to go)
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
    String first = 'Somchai',
    String surname = 'Jaidee',
    String phone = '0812345678',
    String password = 'Passw0rd!',
    String? confirm,
  }) async {
    await tester.enterText(fieldAt(0), first);
    await tester.enterText(fieldAt(1), surname);
    await tester.enterText(fieldAt(2), phone);
    await tester.enterText(fieldAt(3), password);
    await tester.enterText(fieldAt(4), confirm ?? password);
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(signUpButton());
    await tester.pumpAndSettle();
  }

  Future<http.Response> ok(http.Request request) async => json({'message': 'registered'}, 201);

  testWidgets('REG-01 shows 5 fields and the Sign Up button', (tester) async {
    await openRegister(tester, ok);
    expect(find.byType(TextFormField), findsNWidgets(5));
    expect(signUpButton(), findsOneWidget);
    expect(find.text('Already have an account? Sign In'), findsOneWidget);
  });

  testWidgets('REG-02 empty form shows every required error and sends nothing', (tester) async {
    final services = await openRegister(tester, ok);
    await submit(tester);
    expect(find.text('กรุณากรอกชื่อ'), findsOneWidget);
    expect(find.text('กรุณากรอกนามสกุล'), findsOneWidget);
    expect(find.text('กรุณากรอกเบอร์โทรศัพท์'), findsOneWidget);
    expect(find.text('รหัสผ่านต้องยาวอย่างน้อย 8 ตัว'), findsOneWidget);
    expect(services.requests, isEmpty);
  });

  testWidgets('REG-03 password with 7 characters is rejected, 8 is accepted', (tester) async {
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

  testWidgets('REG-04 mismatched passwords show an error', (tester) async {
    final services = await openRegister(tester, ok);
    await fill(tester, password: 'Passw0rd!', confirm: 'Passw0rd?');
    await submit(tester);
    expect(find.text('รหัสผ่านไม่ตรงกัน'), findsOneWidget);
    expect(services.requests, isEmpty);
  });

  testWidgets('REG-05 both password fields are hidden', (tester) async {
    await openRegister(tester, ok);
    expect(textFieldAt(tester, 3).obscureText, isTrue);
    expect(textFieldAt(tester, 4).obscureText, isTrue);
  });

  testWidgets('REG-06 sends trimmed name and phone, and never sends a role', (tester) async {
    final services = await openRegister(tester, ok);
    await fill(tester, first: '  Somchai ', surname: ' Jaidee  ', phone: ' 0812345678 ');
    await submit(tester);
    expect(services.bodyOf('/api/auth/register'), {
      'phone': '0812345678',
      'password': 'Passw0rd!',
      'confirmPassword': 'Passw0rd!',
      'first_name': 'Somchai',
      'surname': 'Jaidee',
    });
  });

  testWidgets('REG-07 success shows a dialog, then "ตกลง" goes back to the previous page', (tester) async {
    await openRegister(tester, ok);
    await fill(tester);
    await submit(tester);
    expect(find.text('Sign Up สำเร็จ'), findsOneWidget);

    await tester.tap(find.text('ตกลง'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsNothing);
    expect(find.text('start page'), findsOneWidget);
  });

  testWidgets('REG-08 phone already used (409) shows the message under the form', (tester) async {
    await openRegister(tester, (request) async => json({'message': 'เบอร์โทรนี้ถูกใช้แล้ว'}, 409));
    await fill(tester);
    await submit(tester);
    expect(find.text(RegisterController.duplicatePhoneMessage), findsOneWidget);
    expect(find.text('Sign Up สำเร็จ'), findsNothing);
    expect(find.byType(RegisterScreen), findsOneWidget);
  });

  testWidgets('REG-09 other server errors show the server message', (tester) async {
    await openRegister(tester, (request) async => json({'message': 'Database is down'}, 500));
    await fill(tester);
    await submit(tester);
    expect(find.text('Database is down'), findsOneWidget);
    expect(find.byType(RegisterScreen), findsOneWidget);
  });

  testWidgets('REG-10 server not running shows the connection error', (tester) async {
    await openRegister(tester, (request) async => throw Exception('connection refused'));
    await fill(tester);
    await submit(tester);
    expect(find.textContaining('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้'), findsOneWidget);
  });

  testWidgets('REG-11 "Already have an account? Sign In" goes back', (tester) async {
    await openRegister(tester, ok);
    await tester.tap(find.text('Already have an account? Sign In'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsNothing);
  });
}
