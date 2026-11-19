// ผู้รับผิดชอบ: Bank (แอดมิน)
// widget test: หน้า Dorms ของแอดมิน
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/core/utils/status_style.dart';
import 'package:hopak_frontend/modules/admin/dorms/view/admin_dorms_tab.dart';
import 'package:hopak_frontend/widgets/ui/ui.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/fake_backend.dart';

/// คิวรอตรวจ: หอใหม่ 1 หอ + คำขอแก้ไข 1 รายการ (GET /api/admin/queue)
final queue = {
  'new_dormitories': [
    {
      'id': 10,
      'name': 'Sunrise Dorm',
      'zone': 'Back gate',
      'owner_username': 'sample_owner_3',
    },
  ],
  'revisions': [
    {'dormitory_id': 12, 'dormitory_name': 'Khampai 3'},
  ],
  'verifications': [],
};

/// หอทั้งหมดหลายสถานะ (GET /api/admin/dormitories)
final allDorms = [
  {
    'id': 12,
    'name': 'Khampai 3',
    'zone': 'Back gate',
    'status': 'changes_pending',
    'owner_username': 'Frame',
  },
  {
    'id': 10,
    'name': 'Sunrise Dorm',
    'zone': 'Back gate',
    'status': 'pending',
    'owner_username': 'sample_owner_3',
  },
  {
    'id': 11,
    'name': 'Moon Dorm',
    'zone': 'Front gate',
    'status': 'published',
    'owner_username': 'sample_owner_2',
  },
  {
    'id': 13,
    'name': 'Closed Dorm',
    'zone': 'Front gate',
    'status': 'suspended',
    'owner_username': 'sample_owner_2',
  },
];

FakeServices backend({
  Object queueBody = const {},
  List<http.Request>? requests,
}) => fakeBackend({
  'GET /api/admin/queue': queueBody is Map && queueBody.isEmpty
      ? queue
      : queueBody,
  'GET /api/admin/dormitories': {'dormitories': allDorms},
  'GET /api/admin/dormitories?status=suspended': {
    'dormitories': allDorms.where((d) => d['status'] == 'suspended').toList(),
  },
  'GET /api/admin/dormitories/10/document': fileResponse(),
  'POST /api/admin/dormitories/10/approve': {'ok': true},
  'POST /api/admin/dormitories/10/reject': {'ok': true},
  'POST /api/admin/dormitories/11/suspend': {'ok': true},
  'POST /api/admin/dormitories/13/restore': {'ok': true},
}, requests: requests);

Future<void> openPage(WidgetTester tester, AppServices services) async {
  useDesktopScreen(tester);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: AdminDormsTab(services: services)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> openAllDorms(WidgetTester tester) async {
  await tester.tap(find.text('All dorms'));
  await tester.pumpAndSettle();
}

/// ปุ่มของการ์ดหอที่มีชื่อ [dorm]
Finder buttonOf(String dorm, Type type, String label) => find.descendant(
  of: find.ancestor(of: find.text(dorm), matching: find.byType(AppCard)).first,
  matching: find.widgetWithText(type, label),
);

http.Request onlyPost(List<http.Request> requests) =>
    requests.where((r) => r.method == 'POST').single;

void main() {
  testWidgets('1. Dorm waiting for review is listed with its owner', (
    tester,
  ) async {
    await openPage(tester, backend());

    expect(find.text('Dorms'), findsWidgets);
    expect(find.text('Sunrise Dorm'), findsOneWidget);
    expect(find.textContaining('by sample_owner_3'), findsOneWidget);
  });

  testWidgets('2. Approve sends the dorm id to the backend', (tester) async {
    final requests = <http.Request>[];
    await openPage(tester, backend(requests: requests));

    await tester.tap(find.widgetWithText(FilledButton, 'Approve').first);
    await tester.pumpAndSettle();

    expect(onlyPost(requests).url.path, '/api/admin/dormitories/10/approve');
  });

  testWidgets('3. Suspend a published dorm with a reason', (tester) async {
    final requests = <http.Request>[];
    await openPage(tester, backend(requests: requests));
    await openAllDorms(tester);

    await tester.tap(buttonOf('Moon Dorm', OutlinedButton, 'Suspend'));
    await tester.pumpAndSettle();
    expect(find.text('Suspend this dorm?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Fake photos');
    await tester.tap(find.widgetWithText(FilledButton, 'Suspend'));
    await tester.pumpAndSettle();

    final post = onlyPost(requests);
    expect(post.url.path, '/api/admin/dormitories/11/suspend');
    expect(jsonDecode(post.body), {'reason': 'Fake photos'});
  });

  testWidgets('4. New dorms and edit requests get different labels', (
    tester,
  ) async {
    await openPage(tester, backend());

    expect(find.text('Sunrise Dorm'), findsOneWidget);
    expect(find.text('New dorm'), findsOneWidget);
    expect(find.text('Khampai 3'), findsOneWidget);
    expect(find.text('Edit request'), findsOneWidget);
  });

  testWidgets('5. Reject a new dorm with a reason', (tester) async {
    final requests = <http.Request>[];
    await openPage(tester, backend(requests: requests));

    await tester.tap(buttonOf('Sunrise Dorm', OutlinedButton, 'Reject'));
    await tester.pumpAndSettle();
    expect(find.text('Reject this dorm?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Photos are blurry');
    await tester.tap(find.widgetWithText(FilledButton, 'Reject'));
    await tester.pumpAndSettle();

    final post = onlyPost(requests);
    expect(post.url.path, '/api/admin/dormitories/10/reject');
    expect(jsonDecode(post.body), {'reason': 'Photos are blurry'});
  });

  testWidgets('6. Status filter loads only the suspended dorms', (
    tester,
  ) async {
    final requests = <http.Request>[];
    await openPage(tester, backend(requests: requests));
    await openAllDorms(tester);
    expect(find.text('Moon Dorm'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Suspended'));
    await tester.pumpAndSettle();

    expect(requests.map((r) => r.url.query), contains('status=suspended'));
    expect(find.text('Closed Dorm'), findsOneWidget);
    expect(find.text('Moon Dorm'), findsNothing);
  });

  testWidgets('7. All dorms shows the status of each dorm', (tester) async {
    await openPage(tester, backend());
    await openAllDorms(tester);

    expect(find.widgetWithText(StatusChip, 'Changes pending'), findsOneWidget);
    expect(find.widgetWithText(StatusChip, 'Pending review'), findsOneWidget);
    expect(find.widgetWithText(StatusChip, 'Published'), findsOneWidget);
    expect(find.widgetWithText(StatusChip, 'Suspended'), findsOneWidget);
  });

  testWidgets('8. Restore brings a suspended dorm back', (tester) async {
    final requests = <http.Request>[];
    await openPage(tester, backend(requests: requests));
    await openAllDorms(tester);

    // หอที่ถูกระงับมีปุ่ม Restore แทน Suspend
    await tester.tap(find.widgetWithText(FilledButton, 'Restore'));
    await tester.pumpAndSettle();

    expect(onlyPost(requests).url.path, '/api/admin/dormitories/13/restore');
  });

  testWidgets('9. Document button downloads the ownership document', (
    tester,
  ) async {
    final requests = <http.Request>[];
    await openPage(tester, backend(requests: requests));

    await tester.tap(buttonOf('Sunrise Dorm', OutlinedButton, 'Document'));
    await tester.pumpAndSettle();

    expect(
      requests.map((r) => r.url.path),
      contains('/api/admin/dormitories/10/document'),
    );
    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets('10. Empty queue says nothing is waiting', (tester) async {
    await openPage(
      tester,
      backend(
        queueBody: {
          'new_dormitories': [],
          'revisions': [],
          'verifications': [],
        },
      ),
    );

    expect(find.text('Nothing waiting for review'), findsOneWidget);
  });
}
