import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/admin/owner_requests/owner_requests_tab.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/admin_test_helpers.dart';


Map<String, dynamic> _verification({
  int id = 7,
  String status = 'pending',
  String? rejectionReason,
}) => {
  'id': id,
  'owner_id': 30,
  'document_url': 'private_uploads/licence.png',
  'status': status,
  'submitted_at': '2026-11-17T05:42:05.000Z',
  'reviewed_at': null,
  'rejection_reason': rejectionReason,
  'owner_username': null,
  'first_name': 'QA',
  'surname': 'Owner',
  'owner_phone': '0899900003',
};

/// ตอบรายการคำขอตามสถานะ โดยให้ pending เปลี่ยนเป็นว่างหลังอนุมัติ/ปฏิเสธ
Future<http.Response> Function(http.Request) _router({
  required List<Map<String, dynamic>> pending,
  required List<http.Request> writes,
  required List<Map<String, dynamic>> rejectedAfter,
}) {
  return (req) async {
    final path = req.url.path;
    if (req.method == 'GET' && path == '/api/admin/verifications') {
      switch (req.url.queryParameters['status']) {
        case 'pending':
          return jsonResponse({'verifications': pending});
        case 'rejected':
          return jsonResponse({'verifications': rejectedAfter});
        default:
          return jsonResponse({'verifications': <Map<String, dynamic>>[]});
      }
    }
    if (req.method == 'POST') {
      writes.add(req);
      pending.clear();
      return jsonResponse({'ok': true});
    }
    return jsonResponse({'error': 'not found'}, 404);
  };
}

Future<void> _pump(
  WidgetTester tester,
  AppServices services,
  VoidCallback onChanged,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AdminQueueTab(services: services, onChanged: onChanged),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('อนุมัติคำขอ: ส่ง approve, แจ้งผล และเรียก onChanged', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.reset);

    final writes = <http.Request>[];
    final pending = [_verification()];
    final services = servicesWith(_router(
      pending: pending,
      writes: writes,
      rejectedAfter: const [],
    ));
    var changed = 0;

    await _pump(tester, services, () => changed++);

    expect(find.text('QA Owner'), findsOneWidget);
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Approve'));
    await tester.pumpAndSettle();

    expect(writes.single.url.path, '/api/admin/verifications/7/approve');
    expect(changed, 1);
    expect(find.text('Approved QA Owner successfully.'), findsOneWidget);
    expect(find.text('QA Owner'), findsNothing);
  });

  testWidgets('ปฏิเสธคำขอ: ต้องมีเหตุผล แล้วส่ง reject พร้อมเหตุผล', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.reset);

    final writes = <http.Request>[];
    final pending = [_verification()];
    final services = servicesWith(_router(
      pending: pending,
      writes: writes,
      rejectedAfter: [_verification(status: 'rejected', rejectionReason: 'เอกสารไม่ชัด')],
    ));
    var changed = 0;

    await _pump(tester, services, () => changed++);

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Reject'));
    await tester.pumpAndSettle();

    // ล้างเหตุผลแล้ว ปุ่มยืนยันต้องกดไม่ได้
    final field = find.byType(TextField);
    await tester.enterText(field, '');
    await tester.pumpAndSettle();
    final confirm = find.widgetWithText(ElevatedButton, 'Reject');
    expect(tester.widget<ElevatedButton>(confirm).onPressed, isNull);
    expect(writes, isEmpty);

    await tester.enterText(field, 'เอกสารไม่ชัด');
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(writes.single.url.path, '/api/admin/verifications/7/reject');
    expect(jsonDecode(writes.single.body), {'reason': 'เอกสารไม่ชัด'});
    expect(changed, 1);
    expect(find.text('Rejected QA Owner. They can correct and resubmit.'), findsOneWidget);
  });

  testWidgets('Approved tab แสดงจำนวนจริงจากข้อมูล ไม่ใช่ค่าคงที่', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.reset);

    final services = servicesWith((req) async {
      if (req.url.queryParameters['status'] == 'approved') {
        return jsonResponse({'verifications': [_verification(id: 1, status: 'approved'), _verification(id: 2, status: 'approved')]});
      }
      return jsonResponse({'verifications': <Map<String, dynamic>>[]});
    });

    await _pump(tester, services, () {});

    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('Owner requests ไม่ overflow บนจอมือถือ', (tester) async {
    await expectPhoneLayout(
      tester,
      AdminQueueTab(services: sampleDataServices()),
    );
  });
}
