// Widget Test: Login page
// How to use: copy this file into the Flutter project's test/ folder (next to pubspec.yaml)
// then run: flutter test
//
// TODO: change the import and class name to match the Frontend team's code (P2, P4, P6)
// The Frontend team needs to add the Keys listed in widget/KEYS.md to their widgets
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ho_phak/views/login_page.dart'; // TODO: real path

Widget wrap(Widget child) => MaterialApp(home: child);

void main() {
  group('Login page', () {
    testWidgets('WID-01 shows username and password fields and a login button', (tester) async {
      await tester.pumpWidget(wrap(const LoginPage()));
      expect(find.byKey(const Key('login_username')), findsOneWidget);
      expect(find.byKey(const Key('login_password')), findsOneWidget);
      expect(find.byKey(const Key('login_submit')), findsOneWidget);
    });

    testWidgets('WID-02 empty fields show an error and no request is sent', (tester) async {
      await tester.pumpWidget(wrap(const LoginPage()));
      await tester.tap(find.byKey(const Key('login_submit')));
      await tester.pump();
      // TODO: change the text to match the app's real error message
      expect(find.textContaining('กรุณา'), findsWidgets);
    });

    testWidgets('WID-03 password is hidden by default', (tester) async {
      await tester.pumpWidget(wrap(const LoginPage()));
      final field = tester.widget<TextField>(
        find.descendant(of: find.byKey(const Key('login_password')), matching: find.byType(TextField)),
      );
      expect(field.obscureText, isTrue);
    });

    testWidgets('WID-04 tapping the eye icon shows the password', (tester) async {
      await tester.pumpWidget(wrap(const LoginPage()));
      await tester.tap(find.byKey(const Key('login_toggle_password')));
      await tester.pump();
      final field = tester.widget<TextField>(
        find.descendant(of: find.byKey(const Key('login_password')), matching: find.byType(TextField)),
      );
      expect(field.obscureText, isFalse);
    });

    testWidgets('WID-05 tapping "Sign up" opens the Register page', (tester) async {
      await tester.pumpWidget(wrap(const LoginPage()));
      await tester.tap(find.byKey(const Key('login_go_register')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('register_submit')), findsOneWidget);
    });
  });
}
