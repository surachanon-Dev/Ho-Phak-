// Widget Test: login page (lib/views/auth/login_view.dart)
// Run: flutter test test/widgets/login_view_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hophak_frontend/views/auth/login_view.dart';
import 'package:hophak_frontend/views/auth/register_view.dart';

import '../helpers/test_app.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> openLogin(WidgetTester tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(page(const LoginView()));
    await tester.pumpAndSettle();
  }

  Future<void> login(WidgetTester tester, String id, String password) async {
    await tester.enterText(find.byKey(const Key('login_id')), id);
    await tester.enterText(find.byKey(const Key('login_password')), password);
    await tester.tap(find.byKey(const Key('login_submit')));
    await settle(tester);
  }

  testWidgets('WID-01 shows the username field, password field and login button', (tester) async {
    await openLogin(tester);
    expect(find.byKey(const Key('login_id')), findsOneWidget);
    expect(find.byKey(const Key('login_password')), findsOneWidget);
    expect(find.byKey(const Key('login_submit')), findsOneWidget);
  });

  testWidgets('WID-02 empty fields show both error messages', (tester) async {
    await openLogin(tester);
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();
    expect(find.text('กรุณากรอกชื่อผู้ใช้หรือเบอร์โทร'), findsOneWidget);
    expect(find.text('กรุณากรอกรหัสผ่าน'), findsOneWidget);
    expect(authOf(tester, find.byType(LoginView)).user, isNull);
  });

  testWidgets('WID-03 password is hidden, tapping the eye icon shows it', (tester) async {
    await openLogin(tester);
    EditableText pw() => tester.widget<EditableText>(
        find.descendant(of: find.byKey(const Key('login_password')), matching: find.byType(EditableText)));
    expect(pw().obscureText, isTrue);
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();
    expect(pw().obscureText, isFalse);
  });

  testWidgets('WID-04 wrong password shows an error and does not log in', (tester) async {
    await openLogin(tester);
    await login(tester, 'Frame', 'wrong-password');
    expect(find.text('ชื่อผู้ใช้/เบอร์โทร หรือรหัสผ่านไม่ถูกต้อง'), findsOneWidget);
    expect(authOf(tester, find.byType(LoginView)).user, isNull);
  });

  testWidgets('WID-05 correct username and password log in as a student', (tester) async {
    await openLogin(tester);
    await login(tester, 'Frame', 'Pass@1234');
    final user = authOf(tester, find.byType(LoginView)).user;
    expect(user, isNotNull);
    expect(user!.role, 'student');
  });

  testWidgets('WID-06 can log in with a phone number instead of a username', (tester) async {
    await openLogin(tester);
    await login(tester, '0629546685', 'Pass@1234'); // Frame's phone
    expect(authOf(tester, find.byType(LoginView)).user?.username, 'Frame');
  });

  testWidgets('WID-07 spaces around the username still work', (tester) async {
    await openLogin(tester);
    await login(tester, '  Frame  ', 'Pass@1234');
    expect(authOf(tester, find.byType(LoginView)).user, isNotNull);
  });

  testWidgets('WID-08 tapping a demo account chip fills in the form', (tester) async {
    await openLogin(tester);
    await tester.tap(find.text('เจ้าของหอ (Big)'));
    await tester.pump();
    expect(textOf(tester, const Key('login_id')), 'Big');
    expect(textOf(tester, const Key('login_password')), 'Pass@1234');
  });

  testWidgets('WID-09 tapping "สมัครสมาชิก" opens the register page', (tester) async {
    await openLogin(tester);
    await tester.tap(find.widgetWithText(TextButton, 'สมัครสมาชิก'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterView), findsOneWidget);
    expect(find.text('สร้างบัญชีผู้ใช้'), findsOneWidget);
  });
}
