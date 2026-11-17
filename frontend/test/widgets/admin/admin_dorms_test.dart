import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/admin/dorms/admin_dorms_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/admin_test_helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Dorms ไม่ overflow บนจอมือถือ', (tester) async {
    await expectPhoneLayout(
      tester,
      AdminDormsTab(services: sampleDataServices()),
    );
  });
}
