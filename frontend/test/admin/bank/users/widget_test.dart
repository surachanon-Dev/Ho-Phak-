// ผู้รับผิดชอบ: Bank (แอดมิน)
// widget test: หน้า Users ของแอดมิน
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/modules/admin/users/view/admin_users_tab.dart';

import '../../../helpers/fake_backend.dart';

Map<String, dynamic> user(
  int id,
  String name,
  String phone, {
  String role = 'owner',
  String status = 'active',
}) => {
  'id': id,
  'username': name,
  'phone': phone,
  'role': role,
  'status': status,
  'is_verified': role == 'owner' ? 1 : 0,
  'created_at': '2026-11-17T10:00:00.000Z',
};

final users = [
  user(1, 'Frame', '0869370918'),
  user(2, 'bank', '0816531282', role: 'student'),
  user(3, 'sample_owner_4', '0800000104', status: 'suspended'),
  user(4, 'karn', '0811111111', role: 'student'),
];

Future<void> openPage(WidgetTester tester) async {
  useDesktopScreen(tester);
  final services = fakeBackend({
    'GET /api/admin/users': {'users': users},
    'GET /api/admin/dormitories': {
      'dormitories': [
        {
          'id': 12,
          'name': 'Khampai 3',
          'owner_id': 1,
          'status': 'changes_pending',
        },
      ],
    },
  });
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: AdminUsersTab(services: services)),
    ),
  );
  await tester.pumpAndSettle();
}

/// เลือกค่าจาก dropdown ตัวกรอง ([current] คือค่าที่แสดงอยู่ตอนนี้)
Future<void> pickFilter(
  WidgetTester tester,
  String current,
  String value,
) async {
  await tester.tap(find.text(current));
  await tester.pumpAndSettle();
  await tester.tap(find.text(value).last); // ตัวเลือกในเมนูที่เปิดขึ้นมา
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('1. Users page lists the users from the backend', (tester) async {
    await openPage(tester);

    expect(find.text('Users'), findsWidgets);
    expect(find.text('4 users · manage owners and students'), findsOneWidget);
    for (final name in ['Frame', 'bank', 'sample_owner_4', 'karn']) {
      expect(find.text(name), findsOneWidget);
    }
  });

  testWidgets('2. Tapping a user opens the user detail page', (tester) async {
    await openPage(tester);

    await tester.tap(find.text('Frame'));
    await tester.pumpAndSettle();

    expect(find.text('Back to users'), findsOneWidget);
    expect(find.text('0869370918'), findsOneWidget);
    expect(find.text('Dorms (1)'), findsOneWidget);
    expect(find.text('Khampai 3'), findsOneWidget);
  });

  testWidgets('3. Search keeps only the matching name or phone', (
    tester,
  ) async {
    await openPage(tester);

    await tester.enterText(find.byType(TextField), 'bank');
    await tester.pumpAndSettle();

    expect(find.text('bank'), findsWidgets); // แถวผู้ใช้ + ช่องค้นหา
    expect(find.text('Frame'), findsNothing);
    expect(find.text('1 users · manage owners and students'), findsOneWidget);
  });

  testWidgets('4. Role filter shows only owners', (tester) async {
    await openPage(tester);

    await pickFilter(tester, 'All roles', 'Owner');

    expect(find.text('Frame'), findsOneWidget);
    expect(find.text('sample_owner_4'), findsOneWidget);
    expect(find.text('bank'), findsNothing);
    expect(find.text('karn'), findsNothing);
  });

  testWidgets('5. Status filter shows only suspended users', (tester) async {
    await openPage(tester);

    await pickFilter(tester, 'All statuses', 'Suspended');

    expect(find.text('sample_owner_4'), findsOneWidget);
    expect(find.text('Frame'), findsNothing);
    expect(find.text('bank'), findsNothing);
  });

  testWidgets('6. Each row shows the role, status and join date', (
    tester,
  ) async {
    await openPage(tester);

    expect(find.text('0869370918'), findsOneWidget);
    expect(find.text('Owner'), findsNWidgets(2));
    expect(find.text('Student'), findsNWidgets(2));
    expect(find.text('Active'), findsNWidgets(3));
    expect(find.text('Suspended'), findsOneWidget);
    expect(find.text('Joined 2026-11-17'), findsNWidgets(4));
  });

  testWidgets('7. Back to users returns to the list', (tester) async {
    await openPage(tester);
    await tester.tap(find.text('Frame'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Back to users'));
    await tester.pumpAndSettle();

    expect(find.text('4 users · manage owners and students'), findsOneWidget);
    expect(find.text('karn'), findsOneWidget);
  });
}
