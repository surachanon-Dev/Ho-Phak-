// ผู้รับผิดชอบ: Plub (เจ้าของหอ)
// widget test: หน้ารายละเอียดหอของเจ้าของ
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/modules/owner/dorm_detail/view/dormitory_detail_screen.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/fake_backend.dart';
import '../../../helpers/owner_data.dart';

Future<void> openDetail(
  WidgetTester tester,
  AppServices services, {
  int dormId = 1,
}) async {
  useDesktopScreen(tester);
  await tester.pumpWidget(
    MaterialApp(
      home: DormitoryDetailScreen(services: services, dormitoryId: dormId),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('1. Dorm info, rooms and actions are shown', (tester) async {
    await openDetail(
      tester,
      fakeBackend(
        ownerRoutes(
          dorms: [ownerDormJson(id: 1, name: 'Baan Suan')],
          reviews: {
            1: [ownerReviewJson(rating: 5), ownerReviewJson(id: 2, rating: 3)],
          },
        ),
      ),
    );

    expect(find.text('Baan Suan'), findsWidgets);
    expect(find.text('Total rooms'), findsOneWidget);
    expect(find.text('Available now'), findsOneWidget);
    expect(find.text('Edit dorm'), findsOneWidget);
    expect(find.text('Delete dorm'), findsOneWidget);
  });

  testWidgets('2. An unknown dorm shows Dorm not found', (tester) async {
    await openDetail(tester, fakeBackend(ownerRoutes()), dormId: 99);

    expect(find.text('Dorm not found'), findsOneWidget);
  });

  testWidgets('3. A rejected dorm shows the admin note', (tester) async {
    await openDetail(
      tester,
      fakeBackend(
        ownerRoutes(
          dorms: [
            ownerDormJson(
              id: 1,
              status: 'rejected',
              rejectionReason: 'Photos are missing',
            ),
          ],
        ),
      ),
    );

    expect(find.textContaining('Photos are missing'), findsOneWidget);
  });

  testWidgets('4. Delete asks first and sends DELETE after confirming', (
    tester,
  ) async {
    final requests = <http.Request>[];
    await openDetail(
      tester,
      fakeBackend(
        ownerRoutes(
          dorms: [ownerDormJson(id: 1)],
          extra: {
            'DELETE /api/owner/dormitories/1': {'ok': true},
          },
        ),
        requests: requests,
      ),
    );

    // ปุ่มลบอยู่ล่างสุดของหน้า จึงขยายจอให้สูงพอเห็นทั้งหน้า
    tester.view.physicalSize = const Size(1600, 2400);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete dorm'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this dorm?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(
      requests.where((r) => r.method == 'DELETE').single.url.path,
      '/api/owner/dormitories/1',
    );
  });
}
