// ผู้รับผิดชอบ: Bank (แอดมิน)
// widget test: หน้า Owner requests
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/modules/admin/owner_requests/view/admin_queue_tab.dart';
import 'package:hopak_frontend/modules/admin/owner_requests/view/widgets/owner_request_widgets.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/fake_backend.dart';

/// คำขอ 1 รายการในรูปแบบเดียวกับ GET /api/admin/verifications
Map<String, dynamic> ownerRequest({
  int id = 7,
  String first = 'QA',
  String surname = 'Owner',
  String phone = '0800000104',
  String status = 'pending',
  String? rejectionReason,
}) => {
  'id': id,
  'owner_id': 30 + id,
  'document_url': 'private_uploads/licence-$id.pdf',
  'status': status,
  'submitted_at': '2026-11-17T05:42:05.000Z',
  'reviewed_at': status == 'pending' ? null : '2026-11-18T05:42:05.000Z',
  'rejection_reason': rejectionReason,
  'first_name': first,
  'surname': surname,
  'owner_phone': phone,
};

/// backend ปลอมที่ตอบแต่ละแท็บตามที่กำหนด
FakeServices backend({
  List<Map<String, dynamic>> pending = const [],
  List<Map<String, dynamic>> approved = const [],
  List<Map<String, dynamic>> rejected = const [],
  List<http.Request>? requests,
}) => fakeBackend({
  'GET /api/admin/verifications?status=pending': {'verifications': pending},
  'GET /api/admin/verifications?status=approved': {'verifications': approved},
  'GET /api/admin/verifications?status=rejected': {'verifications': rejected},
  'GET /api/admin/verifications/7/document': fileResponse(),
  'POST /api/admin/verifications/7/approve': {'ok': true},
  'POST /api/admin/verifications/7/reject': {'ok': true},
}, requests: requests);

Future<void> openPage(WidgetTester tester, AppServices services) async {
  useDesktopScreen(tester);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: AdminQueueTab(services: services)),
    ),
  );
  await tester.pumpAndSettle();
}

/// ปุ่มแท็บ Pending / Approved / Rejected
Finder tab(String label) =>
    find.byWidgetPredicate((w) => w is RequestTabButton && w.label == label);

void main() {
  testWidgets('1. Pending request is listed with the owner name', (
    tester,
  ) async {
    await openPage(tester, backend(pending: [ownerRequest()]));

    expect(find.text('Owner requests'), findsOneWidget);
    expect(find.text('QA Owner'), findsOneWidget);
  });

  testWidgets('2. Approve sends the request and shows a success message', (
    tester,
  ) async {
    final requests = <http.Request>[];
    await openPage(
      tester,
      backend(pending: [ownerRequest()], requests: requests),
    );
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Approve'));
    await tester.pumpAndSettle();

    expect(
      requests.where((r) => r.method == 'POST').single.url.path,
      '/api/admin/verifications/7/approve',
    );
    expect(find.text('Approved QA Owner successfully.'), findsOneWidget);
  });

  testWidgets('3. Reject needs a reason before it is sent', (tester) async {
    final requests = <http.Request>[];
    await openPage(
      tester,
      backend(pending: [ownerRequest()], requests: requests),
    );
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Reject'));
    await tester.pumpAndSettle();

    // ป๊อปอัปเติมเหตุผลสำเร็จรูปไว้ให้ ถ้าลบจนว่าง ปุ่ม Reject ต้องกดไม่ได้
    final confirm = find.widgetWithText(ElevatedButton, 'Reject');
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(confirm).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Blurry document');
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    final post = requests.where((r) => r.method == 'POST').single;
    expect(post.url.path, '/api/admin/verifications/7/reject');
    expect(jsonDecode(post.body), {'reason': 'Blurry document'});
  });

  testWidgets('4. Request detail shows the owner info and the document', (
    tester,
  ) async {
    await openPage(tester, backend(pending: [ownerRequest()]));
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();

    expect(find.text('Owner request'), findsOneWidget);
    expect(find.text('0800000104'), findsOneWidget);
    expect(find.text('Dorm Owner'), findsOneWidget);
    expect(find.text('2026-11-17'), findsOneWidget);
    expect(find.text('licence-7.pdf'), findsOneWidget);
    expect(find.text('Pending'), findsWidgets);
  });

  testWidgets('5. Open document downloads the file and shows it', (
    tester,
  ) async {
    final requests = <http.Request>[];
    await openPage(
      tester,
      backend(pending: [ownerRequest()], requests: requests),
    );
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open document'));
    await tester.pumpAndSettle();

    expect(
      requests.map((r) => r.url.path),
      contains('/api/admin/verifications/7/document'),
    );
    expect(find.text('Open PDF in new tab'), findsOneWidget);
  });

  testWidgets('6. Approved tab lists the approved requests and the count', (
    tester,
  ) async {
    await openPage(
      tester,
      backend(
        pending: [ownerRequest()],
        approved: [
          ownerRequest(id: 1, first: 'Somchai', status: 'approved'),
          ownerRequest(id: 2, first: 'Somsri', status: 'approved'),
        ],
      ),
    );
    expect(
      find.descendant(of: tab('Approved'), matching: find.text('2')),
      findsOneWidget,
    );

    await tester.tap(tab('Approved'));
    await tester.pumpAndSettle();

    expect(find.text('Somchai Owner'), findsOneWidget);
    expect(find.text('Somsri Owner'), findsOneWidget);
    expect(find.text('QA Owner'), findsNothing);
    expect(find.text('View'), findsNWidgets(2));
  });

  testWidgets('7. Rejected tab with no requests shows an empty message', (
    tester,
  ) async {
    await openPage(tester, backend(pending: [ownerRequest()]));

    await tester.tap(tab('Rejected'));
    await tester.pumpAndSettle();

    expect(find.text('No requests'), findsOneWidget);
  });

  testWidgets('8. Rejected request shows the reason given to the owner', (
    tester,
  ) async {
    await openPage(
      tester,
      backend(
        rejected: [
          ownerRequest(
            id: 3,
            first: 'Manee',
            status: 'rejected',
            rejectionReason: 'Blurry document',
          ),
        ],
      ),
    );

    await tester.tap(tab('Rejected'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();

    expect(find.text('Manee Owner'), findsWidgets);
    expect(find.textContaining('Reason: Blurry document'), findsOneWidget);
  });

  testWidgets('9. Search keeps only the request that matches the phone', (
    tester,
  ) async {
    await openPage(
      tester,
      backend(
        pending: [
          ownerRequest(),
          ownerRequest(id: 8, first: 'Other', phone: '0899999999'),
        ],
      ),
    );
    expect(find.text('Other Owner'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '0800000104');
    await tester.pumpAndSettle();

    expect(find.text('QA Owner'), findsOneWidget);
    expect(find.text('Other Owner'), findsNothing);
  });
}
