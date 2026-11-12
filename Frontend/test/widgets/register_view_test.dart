// Widget Test: register page (lib/views/auth/register_view.dart)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hophak_frontend/views/auth/register_view.dart';

import '../helpers/test_app.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // Field order on the page: 0 username, 1 phone, 2 password, 3 confirm
  Finder field(int i) => find.byType(TextFormField).at(i);
  Finder submit() => find.widgetWithText(FilledButton, 'สมัครสมาชิก');

  Future<void> openRegister(WidgetTester tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(page(const RegisterView()));
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester, {String username = '', required String phone, required String pw, String? confirm}) async {
    await tester.enterText(field(0), username);
    await tester.enterText(field(1), phone);
    await tester.enterText(field(2), pw);
    await tester.enterText(field(3), confirm ?? pw);
  }

  testWidgets('WID-10 empty form shows phone and password errors', (tester) async {
    await openRegister(tester);
    await tester.tap(submit());
    await tester.pump();
    expect(find.text('เบอร์โทรต้องขึ้นต้นด้วย 0 และมี 9–10 หลัก'), findsOneWidget);
    expect(find.text('รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร'), findsOneWidget);
  });

  testWidgets('WID-11 phone numbers in the wrong format are rejected', (tester) async {
    await openRegister(tester);
    for (final bad in ['123', '1812345678', '08123', '081234567890', '08-1234-567']) {
      await fill(tester, phone: bad, pw: 'Passw0rd!');
      await tester.tap(submit());
      await tester.pump();
      expect(find.text('เบอร์โทรต้องขึ้นต้นด้วย 0 และมี 9–10 หลัก'), findsOneWidget, reason: 'phone "$bad" should be rejected');
    }
  });

  testWidgets('WID-12 password shorter than 8 characters is rejected', (tester) async {
    await openRegister(tester);
    await fill(tester, phone: '0811110001', pw: '1234567');
    await tester.tap(submit());
    await tester.pump();
    expect(find.text('รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร'), findsOneWidget);
  });

  testWidgets('WID-13 mismatched passwords show an error', (tester) async {
    await openRegister(tester);
    await fill(tester, phone: '0811110002', pw: 'Passw0rd!', confirm: 'Different1');
    await tester.tap(submit());
    await tester.pump();
    expect(find.text('รหัสผ่านไม่ตรงกัน'), findsOneWidget);
  });

  testWidgets('WID-14 username longer than 50 characters is rejected', (tester) async {
    await openRegister(tester);
    await fill(tester, username: 'a' * 51, phone: '0811110003', pw: 'Passw0rd!');
    await tester.tap(submit());
    await tester.pump();
    expect(find.text('ไม่เกิน 50 ตัวอักษร'), findsOneWidget);
  });

  testWidgets('WID-15 choosing "เจ้าของหอพัก" shows the verification notice', (tester) async {
    await openRegister(tester);
    expect(find.textContaining('เอกสารยืนยันตัวตน'), findsNothing);
    await tester.tap(find.text('เจ้าของหอพัก'));
    await tester.pump();
    expect(find.textContaining('เอกสารยืนยันตัวตน'), findsOneWidget);
  });

  testWidgets('WID-16 valid form signs up as a student', (tester) async {
    await openRegister(tester);
    await fill(tester, username: 'qa_student', phone: '0811110004', pw: 'Passw0rd!');
    await tester.tap(submit());
    await settle(tester);
    final user = authOf(tester, find.byType(MaterialApp)).user;
    expect(user, isNotNull);
    expect(user!.role, 'student');
    expect(user.phone, '0811110004');
  });

  testWidgets('WID-17 signing up as an owner saves role owner, not yet verified', (tester) async {
    await openRegister(tester);
    await tester.tap(find.text('เจ้าของหอพัก'));
    await tester.pump();
    await fill(tester, username: 'qa_owner', phone: '0811110005', pw: 'Passw0rd!');
    await tester.tap(submit());
    await settle(tester);
    final user = authOf(tester, find.byType(MaterialApp)).user;
    expect(user?.role, 'owner');
    expect(user?.isVerified, isFalse);
  });

  testWidgets('WID-18 a phone number that is already used shows an error', (tester) async {
    await openRegister(tester);
    await fill(tester, phone: '0629546685', pw: 'Passw0rd!'); // Frame's phone
    await tester.tap(submit());
    await settle(tester);
    expect(find.text('เบอร์โทรนี้ถูกใช้งานแล้ว'), findsOneWidget);
    expect(authOf(tester, find.byType(MaterialApp)).user, isNull);
  });
}
