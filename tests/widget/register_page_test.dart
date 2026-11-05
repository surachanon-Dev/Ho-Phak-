// Widget Test: Register page (user and owner)
// TODO: change the import and class name to match the real code
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ho_phak/views/register_page.dart'; // TODO: real path

Widget wrap(Widget child) => MaterialApp(home: child);

Future<void> fill(WidgetTester t, String key, String text) =>
    t.enterText(find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField)), text);

void main() {
  testWidgets('WID-06 mismatched passwords show an error', (tester) async {
    await tester.pumpWidget(wrap(const RegisterPage()));
    await fill(tester, 'register_username', 'qa_widget');
    await fill(tester, 'register_password', 'Passw0rd!');
    await fill(tester, 'register_confirm', 'different');
    await tester.tap(find.byKey(const Key('register_submit')));
    await tester.pump();
    expect(find.textContaining('ไม่ตรงกัน'), findsOneWidget); // TODO: real message
  });

  testWidgets('WID-07 must accept the terms before signing up', (tester) async {
    await tester.pumpWidget(wrap(const RegisterPage()));
    await fill(tester, 'register_username', 'qa_widget');
    await fill(tester, 'register_password', 'Passw0rd!');
    await fill(tester, 'register_confirm', 'Passw0rd!');
    await tester.tap(find.byKey(const Key('register_submit')));
    await tester.pump();
    expect(find.textContaining('ยอมรับ'), findsWidgets); // TODO: real message
  });

  testWidgets('WID-08 owner version has a field for uploading an ownership document', (tester) async {
    await tester.pumpWidget(wrap(const RegisterPage(role: 'owner'))); // TODO: if it is a separate page, change the class
    expect(find.byKey(const Key('register_upload_doc')), findsOneWidget);
  });
}
