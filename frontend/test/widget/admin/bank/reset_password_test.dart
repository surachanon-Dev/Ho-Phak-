// ผู้รับผิดชอบ: Bank (แอดมิน)
// ไฟล์นี้เป็นเทสต์ widget ของปุ่มรีเซ็ตรหัสผ่านในหน้ารายละเอียดผู้ใช้
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/admin/user_detail/admin_user_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/admin_test_helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('แอดมินกด Reset password แล้วเห็นรหัสชั่วคราว', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 1600);
    addTearDown(tester.view.reset);

    final posted = <String>[];
    final services = servicesWith((req) async {
      final path = req.url.path;
      if (path == '/api/admin/users') {
        return jsonResponse({
          'users': [
            {
              'id': 7,
              'username': 'beam',
              'phone': '0861112222',
              'role': 'student',
              'status': 'active',
              'is_verified': 0,
              'created_at': '2026-11-01T10:00:00.000Z',
            },
          ],
        });
      }
      if (path == '/api/admin/dormitories') {
        return jsonResponse({'dormitories': []});
      }
      if (path == '/api/admin/users/7/reset-password') {
        posted.add(path);
        return jsonResponse({'temporary_password': 'Ab3kPq9xYz'});
      }
      return jsonResponse({});
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminUserDetailScreen(
            services: services,
            userId: 7,
            onBack: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Reset password'));
    await tester.tap(find.text('Reset password'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(posted, ['/api/admin/users/7/reset-password']);
    expect(find.text('Temporary password'), findsOneWidget);
    expect(find.text('Ab3kPq9xYz'), findsOneWidget);
  });
}
