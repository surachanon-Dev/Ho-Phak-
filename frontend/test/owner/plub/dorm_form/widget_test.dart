// ผู้รับผิดชอบ: Plub (เจ้าของหอ)
// widget test: ฟอร์มเพิ่ม/แก้ไขหอ
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/model/dormitory.dart';
import 'package:hopak_frontend/modules/owner/dorm_form/view/dormitory_form_screen.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/fake_backend.dart';
import '../../../helpers/owner_data.dart';

Future<void> openForm(
  WidgetTester tester,
  AppServices services, {
  Dormitory? existing,
}) async {
  useDesktopScreen(tester);
  await tester.pumpWidget(
    MaterialApp(
      home: DormitoryFormScreen(services: services, existing: existing),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapSubmit(WidgetTester tester) async {
  final submit = find.text('Submit for review');
  await tester.ensureVisible(submit);
  await tester.tap(submit);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('1. Submitting an empty form shows required errors', (
    tester,
  ) async {
    final requests = <http.Request>[];
    await openForm(tester, fakeBackend(ownerRoutes(), requests: requests));

    await tapSubmit(tester);

    expect(find.text('This field is required'), findsWidgets);
    expect(requests.where((r) => r.method == 'POST'), isEmpty);
  });

  testWidgets('2. Editing a dorm fills the form with its current values', (
    tester,
  ) async {
    final dorm = Dormitory.fromJson(
      ownerDormJson(id: 1, name: 'Baan Suan', price: 3200),
    );
    await openForm(
      tester,
      fakeBackend(ownerRoutes(dorms: [ownerDormJson(id: 1)])),
      existing: dorm,
    );

    expect(find.widgetWithText(TextFormField, 'Baan Suan'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '3200'), findsOneWidget);
  });

  testWidgets('3. Available rooms cannot exceed total rooms', (tester) async {
    final dorm = Dormitory.fromJson(
      ownerDormJson(id: 1, total: 10, available: 4),
    );
    await openForm(
      tester,
      fakeBackend(ownerRoutes(dorms: [ownerDormJson(id: 1)])),
      existing: dorm,
    );

    await tester.enterText(find.widgetWithText(TextFormField, '4'), '20');
    await tapSubmit(tester);

    expect(
      find.text('Available rooms cannot exceed total rooms'),
      findsOneWidget,
    );
  });
}
