import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/screens/admin/admin_user_detail_screen.dart';
import 'package:hopak_frontend/services/app_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/admin_test_helpers.dart';


Map<String, dynamic> _row({
  required int id,
  required String role,
  required String status,
  String username = 'bank owner',
  String? suspensionReason,
}) => {
  'id': id,
  'username': username,
  'phone': '0812345678',
  'role': role,
  'status': status,
  'is_verified': 1,
  'created_at': '2026-11-10T10:00:00.000Z',
  'suspension_reason': suspensionReason,
  'suspended_at': suspensionReason == null ? null : '2026-11-12T08:30:00.000Z',
};

Future<void> _pumpDetail(
  WidgetTester tester,
  AppServices services, {
  int userId = 5,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AdminUserDetailScreen(
          services: services,
          userId: userId,
          onBack: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('เจ้าของแสดงหอของตัวเอง และระงับพร้อมเหตุผล', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 1600);
    addTearDown(tester.view.reset);

    var suspended = false;
    final posted = <String>[];
    final services = servicesWith((request) async {
      final path = request.url.path;
      if (path == '/api/admin/users') {
        return jsonResponse({
          'users': [
            _row(
              id: 5,
              role: 'owner',
              status: suspended ? 'suspended' : 'active',
              suspensionReason: suspended ? 'รายงานซ้ำ' : null,
            ),
          ],
        });
      }
      if (path == '/api/admin/dormitories') {
        return jsonResponse({
          'dormitories': [
            {'id': 1, 'name': 'หอพักสุข', 'owner_id': 5, 'status': 'published'},
            {'id': 2, 'name': 'หอพักอื่น', 'owner_id': 9, 'status': 'hidden'},
          ],
        });
      }
      if (path == '/api/admin/users/5/suspend') {
        posted.add(jsonDecode(request.body)['reason'] as String);
        suspended = true;
        return jsonResponse({'ok': true});
      }
      return jsonResponse({'error': 'not found'}, 404);
    });

    await _pumpDetail(tester, services);

    expect(find.text('bank owner'), findsOneWidget);
    expect(find.text('0812345678'), findsOneWidget);
    expect(find.text('Dorms (1)'), findsOneWidget);
    expect(find.text('หอพักสุข'), findsOneWidget);
    expect(find.text('หอพักอื่น'), findsNothing);
    expect(find.text('Published'), findsOneWidget);

    await tester.tap(find.text('Suspend account'));
    await tester.pumpAndSettle();

    final confirm = find.widgetWithText(FilledButton, 'Suspend');
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'รายงานซ้ำ');
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(posted, ['รายงานซ้ำ']);
    expect(find.text('Lift suspension'), findsOneWidget);
    expect(find.textContaining('Account suspended by Admin'), findsOneWidget);
    expect(find.textContaining('Reason: รายงานซ้ำ'), findsOneWidget);
  });

  testWidgets('นักศึกษาที่ถูกระงับเห็นเหตุผลและยกเลิกการระงับได้', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 1600);
    addTearDown(tester.view.reset);

    var restored = false;
    final services = servicesWith((request) async {
      final path = request.url.path;
      if (path == '/api/admin/users') {
        return jsonResponse({
          'users': [
            restored
                ? _row(id: 5, role: 'student', status: 'active', username: 'stu')
                : _row(
                    id: 5,
                    role: 'student',
                    status: 'suspended',
                    username: 'stu',
                    suspensionReason: 'ละเมิดกติกา',
                  ),
          ],
        });
      }
      if (path == '/api/admin/users/5/restore') {
        restored = true;
        return jsonResponse({'ok': true});
      }
      return jsonResponse({'error': 'not found'}, 404);
    });

    await _pumpDetail(tester, services);

    expect(find.textContaining('Reason: ละเมิดกติกา'), findsOneWidget);
    expect(find.text('Dorms (0)'), findsNothing);
    expect(find.text('Suspended'), findsWidgets);

    await tester.tap(find.text('Lift suspension'));
    await tester.pumpAndSettle();

    expect(find.text('Suspend account'), findsOneWidget);
    expect(find.textContaining('Account suspended by Admin'), findsNothing);
  });

  testWidgets('ไม่พบผู้ใช้แสดงข้อความและปุ่มกลับ', (tester) async {
    final services = servicesWith((request) async {
      if (request.url.path == '/api/admin/users') {
        return jsonResponse({'users': <Map<String, dynamic>>[]});
      }
      return jsonResponse({'error': 'not found'}, 404);
    });

    await _pumpDetail(tester, services, userId: 99);

    expect(find.text('This user no longer exists.'), findsOneWidget);
    expect(find.text('Back to users'), findsOneWidget);
  });
}
