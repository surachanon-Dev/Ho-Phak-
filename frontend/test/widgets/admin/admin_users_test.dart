import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/admin/users/admin_users_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/admin_test_helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Users ไม่ overflow บนจอมือถือ', (tester) async {
    await expectPhoneLayout(
      tester,
      AdminUsersTab(services: sampleDataServices()),
    );
  });
}
