// ผู้รับผิดชอบ: Kren (เจ้าของหอ)
// widget test: หน้าเปลี่ยนรหัสผ่านของเจ้าของหอ
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/modules/owner/change_password/view/change_password_screen.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/fake_backend.dart';
import '../../../helpers/owner_data.dart';

Future<void> openChangePassword(
  WidgetTester tester,
  AppServices services,
) async {
  useDesktopScreen(tester);
  await tester.pumpWidget(
    MaterialApp(home: ChangePasswordScreen(services: services)),
  );
  await tester.pumpAndSettle();
}

Future<void> tapUpdate(WidgetTester tester) async {
  final update = find.text('Update password');
  await tester.ensureVisible(update);
  await tester.tap(update);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('1. Empty fields show the required messages', (tester) async {
    await openChangePassword(tester, fakeBackend(ownerRoutes()));

    await tapUpdate(tester);

    expect(find.text('Enter your current password'), findsOneWidget);
    expect(find.text('Use at least 8 characters'), findsOneWidget);
  });

  testWidgets('2. A confirmation that does not match is rejected', (
    tester,
  ) async {
    await openChangePassword(tester, fakeBackend(ownerRoutes()));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'oldpass1');
    await tester.enterText(fields.at(1), 'newpass123');
    await tester.enterText(fields.at(2), 'different');
    await tapUpdate(tester);

    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('3. The new password must differ from the current one', (
    tester,
  ) async {
    await openChangePassword(tester, fakeBackend(ownerRoutes()));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'samepass1');
    await tester.enterText(fields.at(1), 'samepass1');
    await tester.enterText(fields.at(2), 'samepass1');
    await tapUpdate(tester);

    expect(find.text('New password must be different'), findsOneWidget);
  });

  testWidgets('4. A valid form sends PUT /api/me/password', (tester) async {
    final requests = <http.Request>[];
    await openChangePassword(
      tester,
      fakeBackend(
        ownerRoutes(
          extra: {
            'PUT /api/me/password': {'message': 'ok'},
          },
        ),
        requests: requests,
      ),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'oldpass1');
    await tester.enterText(fields.at(1), 'newpass123');
    await tester.enterText(fields.at(2), 'newpass123');
    await tapUpdate(tester);

    final put = requests.singleWhere((r) => r.method == 'PUT');
    expect(put.url.path, '/api/me/password');
    expect(jsonDecode(put.body), {
      'current_password': 'oldpass1',
      'new_password': 'newpass123',
    });
  });
}
