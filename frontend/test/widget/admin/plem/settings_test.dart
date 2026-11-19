// ผู้รับผิดชอบ: Plem (แอดมิน)
// ไฟล์นี้เป็นเทสต์ widget ของหน้าที่ระบุในชื่อไฟล์
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/admin/settings/admin_settings_tab.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/admin_test_helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Settings masks all password fields', (tester) async {
    setDesktopSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: AdminSettingsTab(
          services: servicesWith((_) async => jsonResponse({})),
        ),
      ),
    );

    final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields, hasLength(3));
    expect(fields.every((field) => field.obscureText), isTrue);
  });

  testWidgets('Settings submits the password form and clears it on success', (
    tester,
  ) async {
    final writes = <http.Request>[];
    await _openSettings(tester, (request) async {
      if (request.method == 'GET') return jsonResponse(adminAccountFixture);
      writes.add(request);
      return jsonResponse({});
    });

    await _submitPassword(tester, confirmation: 'new-test-password');

    final request = writes.single;
    expect(request.method, 'PUT');
    expect(request.url.path, '/api/me/password');
    expect(jsonDecode(request.body), {
      'current_password': 'old-test-password',
      'new_password': 'new-test-password',
    });
    expect(find.text('เปลี่ยนรหัสผ่านแล้ว'), findsOneWidget);
    expect(
      tester
          .widgetList<TextField>(find.byType(TextField))
          .map((field) => field.controller?.text),
      ['', '', ''],
    );
  });

  testWidgets(
    'Settings reports a mismatched password before sending a request',
    (tester) async {
      final writes = <http.Request>[];
      await _openSettings(tester, (request) async {
        if (request.method != 'GET') writes.add(request);
        return jsonResponse(adminAccountFixture);
      });

      await _submitPassword(tester, confirmation: 'different-password');

      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(writes, isEmpty);
    },
  );

  testWidgets('Settings ไม่ overflow บนจอมือถือ', (tester) async {
    await expectPhoneLayout(
      tester,
      AdminSettingsTab(services: sampleDataServices()),
    );
  });
}

Future<void> _openSettings(WidgetTester tester, RequestHandler handler) async {
  setDesktopSize(tester);
  await tester.pumpWidget(
    MaterialApp(home: AdminSettingsTab(services: servicesWith(handler))),
  );
  await tester.pumpAndSettle();
}

Future<void> _submitPassword(
  WidgetTester tester, {
  required String confirmation,
}) async {
  Finder field(String label) => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label,
  );

  await tester.enterText(field('Current password'), 'old-test-password');
  await tester.enterText(field('New password'), 'new-test-password');
  await tester.enterText(field('Confirm new password'), confirmation);
  await tester.tap(find.widgetWithText(FilledButton, 'Update password'));
  await tester.pumpAndSettle();
}
