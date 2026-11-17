// ผู้รับผิดชอบ: Plem (แอดมิน)
// ไฟล์นี้เป็นเทสต์ widget ของหน้าที่ระบุในชื่อไฟล์
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/admin/activity_log/admin_logs_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/admin_test_helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'Activity Log displays loaded actions and refreshes an empty list',
    (tester) async {
      var reads = 0;
      final services = servicesWith((request) async {
        expect(request.url.path, '/api/admin/logs');
        reads++;
        return jsonResponse({
          'logs': reads == 1 ? [logFixture] : [],
        });
      });
      await tester.pumpWidget(
        MaterialApp(home: AdminLogsTab(services: services)),
      );
      await tester.pumpAndSettle();

      expect(find.text('review.hide'), findsOneWidget);
      await tester.tap(find.byTooltip('รีเฟรช'));
      await tester.pumpAndSettle();
      expect(find.text('ยังไม่มีประวัติ'), findsOneWidget);
      expect(reads, 2);
    },
  );

  testWidgets('Activity log ไม่ overflow บนจอมือถือ', (tester) async {
    await expectPhoneLayout(
      tester,
      AdminLogsTab(services: sampleDataServices()),
    );
  });
}
