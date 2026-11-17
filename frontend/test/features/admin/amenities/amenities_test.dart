import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/admin/amenities/amenities_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/admin_test_helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Amenities ไม่ overflow บนจอมือถือ', (tester) async {
    await expectPhoneLayout(
      tester,
      AdminAmenitiesTab(services: sampleDataServices()),
    );
  });
}
