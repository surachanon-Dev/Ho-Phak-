import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hophak_frontend/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows the login screen when nobody is logged in', (tester) async {
    SharedPreferences.setMockInitialValues({});
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byKey(const Key('login_id')), findsOneWidget);
  });
}
