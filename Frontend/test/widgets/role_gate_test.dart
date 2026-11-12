// Widget Test: after login the app opens the area that matches the role (lib/app.dart → RoleGate)
// The student area is checked in login_view_test.dart (WID-05), because it contains the map,
// which needs internet to load tiles and does not work inside widget tests.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hophak_frontend/app.dart';
import 'package:hophak_frontend/views/admin/admin_shell.dart';
import 'package:hophak_frontend/views/auth/login_view.dart';
import 'package:hophak_frontend/views/owner/owner_shell.dart';

import '../helpers/test_app.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> openApp(WidgetTester tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(withProviders(const HoPhakApp(), initAuth: true));
    await settle(tester);
  }

  Future<void> login(WidgetTester tester, String id) async {
    await tester.enterText(find.byKey(const Key('login_id')), id);
    await tester.enterText(find.byKey(const Key('login_password')), 'Pass@1234');
    await tester.tap(find.byKey(const Key('login_submit')));
    await settle(tester);
  }

  testWidgets('WID-44 nobody logged in → login page', (tester) async {
    await openApp(tester);
    expect(find.byType(LoginView), findsOneWidget);
  });

  testWidgets('WID-45 owner logs in → owner area with the "เพิ่มหอพัก" button', (tester) async {
    await openApp(tester);
    await login(tester, 'Big');
    expect(find.byType(LoginView), findsNothing);
    expect(find.byType(OwnerShell), findsOneWidget);
    expect(find.byKey(const Key('add_dorm')), findsOneWidget);
  });

  testWidgets('WID-46 admin logs in → admin area, not the owner area', (tester) async {
    await openApp(tester);
    await login(tester, 'admin');
    expect(find.byType(AdminShell), findsOneWidget);
    expect(find.byType(OwnerShell), findsNothing);
  });

  testWidgets('WID-47 a saved login is restored when the app opens again', (tester) async {
    SharedPreferences.setMockInitialValues({'mock_user_id': 2}); // Big (owner)
    await openApp(tester);
    expect(find.byType(OwnerShell), findsOneWidget);
  });
}
