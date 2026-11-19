// ผู้รับผิดชอบ: Kren (เจ้าของหอ)
// widget test: หน้าตั้งค่าการแจ้งเตือนของเจ้าของหอ
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/modules/owner/notification_settings/view/notification_settings_screen.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/fake_backend.dart';
import '../../../helpers/owner_data.dart';

Future<void> openSettings(WidgetTester tester, AppServices services) async {
  useDesktopScreen(tester);
  await tester.pumpWidget(
    MaterialApp(home: NotificationSettingsScreen(services: services)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('1. The owner sees the three owner options', (tester) async {
    await openSettings(tester, fakeBackend(ownerRoutes()));

    expect(find.text('Notification settings'), findsOneWidget);
    expect(find.text('New messages'), findsOneWidget);
    expect(find.text('Approval updates'), findsOneWidget);
    expect(find.text('New reviews'), findsOneWidget);
    expect(find.text('Review updates'), findsNothing);
  });

  testWidgets('2. Switches start from the saved settings', (tester) async {
    await openSettings(
      tester,
      fakeBackend(
        ownerRoutes(
          notificationPrefs: {
            'messages': false,
            'approvals': true,
            'reviews': true,
          },
        ),
      ),
    );

    bool isOn(String label) => tester
        .widget<SwitchListTile>(find.widgetWithText(SwitchListTile, label))
        .value;
    expect(isOn('New messages'), isFalse);
    expect(isOn('Approval updates'), isTrue);
    expect(isOn('New reviews'), isTrue);
  });

  testWidgets('3. Turning on New reviews saves it to the server', (
    tester,
  ) async {
    final requests = <http.Request>[];
    await openSettings(
      tester,
      fakeBackend(
        ownerRoutes(
          extra: {
            'PUT /api/me/notification-settings': {'ok': true},
          },
        ),
        requests: requests,
      ),
    );

    await tester.tap(find.text('New reviews'));
    await tester.pumpAndSettle();

    final put = requests.singleWhere((r) => r.method == 'PUT');
    expect(put.url.path, '/api/me/notification-settings');
    expect(jsonDecode(put.body)['reviews'], isTrue);
  });
}
