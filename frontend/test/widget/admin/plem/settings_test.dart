// ผู้รับผิดชอบ: Plem (แอดมิน)
// ไฟล์นี้เป็นเทสต์ widget ของหน้าที่ระบุในชื่อไฟล์
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/admin/settings/settings_tab.dart';
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

  testWidgets('Settings ไม่ overflow บนจอมือถือ', (tester) async {
    await expectPhoneLayout(
      tester,
      AdminSettingsTab(services: sampleDataServices()),
    );
  });
}
