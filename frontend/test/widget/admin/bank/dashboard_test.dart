// ผู้รับผิดชอบ: Bank (แอดมิน)
// ไฟล์นี้เป็นเทสต์ widget ของหน้าที่ระบุในชื่อไฟล์
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/admin/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/admin_test_helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Dashboard (AdminHomeScreen) ไม่ overflow บนจอมือถือ', (tester) async {
    await expectPhoneLayout(
      tester,
      AdminHomeScreen(services: sampleDataServices()),
    );
  });
}
