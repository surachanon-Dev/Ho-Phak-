// ผู้รับผิดชอบ: Karn (นักศึกษา)
// widget test: หน้าการแจ้งเตือน
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/modules/notifications/view/notifications_screen.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/fake_backend.dart';
import '../../../helpers/student_data.dart';

Future<void> openPage(WidgetTester tester, AppServices services) async {
  useDesktopScreen(tester);
  await tester.pumpWidget(
    MaterialApp(home: NotificationsScreen(services: services)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('1. Notifications are listed with their titles', (tester) async {
    await openPage(
      tester,
      fakeBackend({
        'GET /api/notifications': {
          'notifications': [
            notificationJson(id: 1, title: 'Your review was published'),
            notificationJson(id: 2, title: 'New message', read: true),
          ],
        },
      }),
    );

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Your review was published'), findsOneWidget);
    expect(find.text('New message'), findsOneWidget);
  });

  testWidgets('2. No notifications shows an empty message', (tester) async {
    await openPage(
      tester,
      fakeBackend({
        'GET /api/notifications': {'notifications': []},
      }),
    );

    expect(find.text('No notifications yet'), findsOneWidget);
  });

  testWidgets('3. Tapping an unread notification marks it as read', (
    tester,
  ) async {
    final requests = <http.Request>[];
    await openPage(
      tester,
      fakeBackend({
        'GET /api/notifications': {
          'notifications': [notificationJson(id: 1)],
        },
        'PATCH /api/notifications/1/read': {'ok': true},
      }, requests: requests),
    );

    await tester.tap(find.text('Your review was published'));
    await tester.pumpAndSettle();

    expect(
      requests.where((r) => r.method == 'PATCH').single.url.path,
      '/api/notifications/1/read',
    );
  });
}
