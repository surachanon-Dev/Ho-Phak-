// ผู้รับผิดชอบ: Plem (แอดมิน)
// ไฟล์นี้เป็นเทสต์ widget ของหน้าที่ระบุในชื่อไฟล์
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/admin/activity_log/activity_log_tab.dart';
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

  testWidgets('Activity Log retains the last entries when a refresh fails', (
    tester,
  ) async {
    var reads = 0;
    final services = servicesWith((request) async {
      expect(request.url.path, '/api/admin/logs');
      reads++;
      if (reads == 1) {
        return jsonResponse({
          'logs': [logFixture],
        });
      }
      return jsonResponse({'message': 'Cannot reload activity log'}, 503);
    });
    await tester.pumpWidget(
      MaterialApp(home: AdminLogsTab(services: services)),
    );
    await tester.pumpAndSettle();
    expect(find.text('review.hide'), findsOneWidget);

    await tester.tap(find.byTooltip('รีเฟรช'));
    await tester.pumpAndSettle();

    expect(reads, 2);
    expect(find.text('review.hide'), findsOneWidget);
    expect(find.text('Cannot reload activity log'), findsOneWidget);
  });

  testWidgets('Activity log ไม่ overflow บนจอมือถือ', (tester) async {
    await expectPhoneLayout(
      tester,
      AdminLogsTab(services: sampleDataServices()),
    );
  });
}
