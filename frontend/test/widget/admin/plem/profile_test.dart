// ผู้รับผิดชอบ: Plem (แอดมิน)
// ไฟล์นี้เป็นเทสต์ widget ของหน้าที่ระบุในชื่อไฟล์
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/admin/profile/admin_profile_tab.dart';
import 'package:hopak_frontend/features/auth/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/admin_test_helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the admin account confirms sign-out and returns to Login', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'jwt_token': 'widget-test-token'});
    final writes = <String>[];
    final services = servicesWith((request) async {
      if (request.method == 'POST') writes.add(request.url.path);
      return request.url.path == '/api/me'
          ? jsonResponse(adminAccountFixture)
          : jsonResponse({});
    });
    await services.tokens.load();
    await tester.pumpWidget(
      MaterialApp(home: AdminProfileTab(services: services)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test Admin'), findsOneWidget);
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(writes, isEmpty);

    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pumpAndSettle();
    expect(writes, ['/api/auth/logout']);
    expect(services.tokens.token, isNull);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Profile ไม่ overflow บนจอมือถือ', (tester) async {
    await expectPhoneLayout(
      tester,
      AdminProfileTab(services: sampleDataServices()),
    );
  });
}
