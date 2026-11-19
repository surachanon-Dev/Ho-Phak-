// ผู้รับผิดชอบ: Plem (แอดมิน)
// ไฟล์นี้เป็นเทสต์ widget ของหน้าที่ระบุในชื่อไฟล์
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/admin/reviews/admin_reviews_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/admin_test_helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'Reviews keeps an open review and refreshes the displayed list',
    (tester) async {
      setDesktopSize(tester);
      final writes = <String>[];
      final services = servicesWith((request) async {
        if (request.method == 'POST') {
          writes.add(request.url.path);
          return jsonResponse({});
        }
        return jsonResponse({
          'reviews': writes.isEmpty ? [reviewFixture] : [],
        });
      });
      await tester.pumpWidget(
        MaterialApp(home: AdminReviewsTab(services: services)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hillview Dorm'), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Keep review'));
      await tester.pumpAndSettle();

      expect(writes, ['/api/admin/reviews/9/publish']);
      expect(find.text('Hillview Dorm'), findsNothing);
      expect(find.text('No reviews with this status'), findsOneWidget);
    },
  );

  testWidgets('Reviews loads published reviews when Kept is selected', (
    tester,
  ) async {
    setDesktopSize(tester);
    final statuses = <String?>[];
    final services = servicesWith((request) async {
      expect(request.url.path, '/api/admin/reviews');
      final status = request.url.queryParameters['status'];
      statuses.add(status);
      return jsonResponse({
        'reviews': status == 'published'
            ? [
                {
                  ...reviewFixture,
                  'id': 10,
                  'dormitory_name': 'Kept Dorm',
                  'status': 'published',
                },
              ]
            : [reviewFixture],
      });
    });
    await tester.pumpWidget(
      MaterialApp(home: AdminReviewsTab(services: services)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hillview Dorm'), findsOneWidget);

    await tester.tap(find.widgetWithText(Tab, 'Kept'));
    await tester.pumpAndSettle();

    expect(statuses, ['pending', 'published']);
    expect(find.text('Kept Dorm'), findsOneWidget);
    expect(find.text('Hillview Dorm'), findsNothing);
  });

  testWidgets('Reviews keeps the open review visible when Keep fails', (
    tester,
  ) async {
    setDesktopSize(tester);
    final writes = <String>[];
    final services = servicesWith((request) async {
      if (request.method == 'POST') {
        writes.add(request.url.path);
        return jsonResponse({'message': 'Cannot keep review'}, 503);
      }
      return jsonResponse({
        'reviews': [reviewFixture],
      });
    });
    await tester.pumpWidget(
      MaterialApp(home: AdminReviewsTab(services: services)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Keep review'));
    await tester.pumpAndSettle();

    expect(writes, ['/api/admin/reviews/9/publish']);
    expect(find.text('Hillview Dorm'), findsOneWidget);
    expect(find.text('Cannot keep review'), findsOneWidget);
  });

  testWidgets('Reviews ไม่ overflow บนจอมือถือ', (tester) async {
    await expectPhoneLayout(
      tester,
      AdminReviewsTab(services: sampleDataServices()),
    );
  });
}
