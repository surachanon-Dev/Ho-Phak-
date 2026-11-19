// ผู้รับผิดชอบ: Bank (แอดมิน)
// widget test: หน้ารายละเอียดผู้ใช้
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/modules/admin/user_detail/view/admin_user_detail_screen.dart';

import '../../../helpers/fake_backend.dart';

Widget detail(AppServices services, int userId) => MaterialApp(
  home: Scaffold(
    body: AdminUserDetailScreen(
      services: services,
      userId: userId,
      onBack: () {},
    ),
  ),
);

void main() {
  testWidgets('1. Owner detail shows the phone and their dorms', (
    tester,
  ) async {
    useDesktopScreen(tester);
    final services = fakeBackend({
      'GET /api/admin/users': {
        'users': [
          {
            'id': 5,
            'username': 'bank owner',
            'phone': '0812345678',
            'role': 'owner',
            'status': 'active',
            'is_verified': 1,
            'created_at': '2026-11-10T10:00:00.000Z',
          },
        ],
      },
      'GET /api/admin/dormitories': {
        'dormitories': [
          {
            'id': 1,
            'name': 'Sunrise Dorm',
            'owner_id': 5,
            'status': 'published',
          },
        ],
      },
    });

    await tester.pumpWidget(detail(services, 5));
    await tester.pumpAndSettle();

    expect(find.text('bank owner'), findsOneWidget);
    expect(find.text('0812345678'), findsOneWidget);
    expect(find.text('Dorms (1)'), findsOneWidget);
    expect(find.text('Sunrise Dorm'), findsOneWidget);
  });

  testWidgets('2. Reset password shows the temporary password', (tester) async {
    useDesktopScreen(tester);
    final services = fakeBackend({
      'GET /api/admin/users': {
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
      },
      'GET /api/admin/dormitories': {'dormitories': []},
      'POST /api/admin/users/7/reset-password': {
        'temporary_password': 'Ab3kPq9xYz',
      },
    });

    await tester.pumpWidget(detail(services, 7));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Reset password'));
    await tester.tap(find.text('Reset password'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(find.text('Temporary password'), findsOneWidget);
    expect(find.text('Ab3kPq9xYz'), findsOneWidget);
  });

  testWidgets('3. Unknown user shows a message and a back button', (
    tester,
  ) async {
    useDesktopScreen(tester);
    final services = fakeBackend({
      'GET /api/admin/users': {'users': []},
    });

    await tester.pumpWidget(detail(services, 99));
    await tester.pumpAndSettle();

    expect(find.text('This user no longer exists.'), findsOneWidget);
    expect(find.text('Back to users'), findsOneWidget);
  });

  testWidgets('4. Suspend needs a reason and then shows the suspension', (
    tester,
  ) async {
    useDesktopScreen(tester);
    var suspended = false;
    final services = fakeBackend({
      // คำตอบเปลี่ยนตามสถานะ: หลังระงับ backend จะตอบว่าผู้ใช้ถูกระงับแล้ว
      'GET /api/admin/users': () => {
        'users': [
          student(
            status: suspended ? 'suspended' : 'active',
            reason: suspended ? 'Spam' : null,
          ),
        ],
      },
      'POST /api/admin/users/7/suspend': () {
        suspended = true;
        return {'ok': true};
      },
    });

    await tester.pumpWidget(detail(services, 7));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Suspend account'));
    await tester.tap(find.text('Suspend account'));
    await tester.pumpAndSettle();

    // ยังไม่กรอกเหตุผล: ปุ่ม Suspend กดไม่ได้
    final confirm = find.widgetWithText(FilledButton, 'Suspend');
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Spam');
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(find.text('Lift suspension'), findsOneWidget);
    expect(find.textContaining('Reason: Spam'), findsOneWidget);
  });

  testWidgets('5. Lift suspension brings the account back', (tester) async {
    useDesktopScreen(tester);
    var suspended = true;
    final services = fakeBackend({
      'GET /api/admin/users': () => {
        'users': [
          student(
            status: suspended ? 'suspended' : 'active',
            reason: suspended ? 'Spam' : null,
          ),
        ],
      },
      'POST /api/admin/users/7/restore': () {
        suspended = false;
        return {'ok': true};
      },
    });

    await tester.pumpWidget(detail(services, 7));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Lift suspension'));
    await tester.tap(find.text('Lift suspension'));
    await tester.pumpAndSettle();

    expect(find.text('Suspend account'), findsOneWidget);
    expect(find.textContaining('Reason: Spam'), findsNothing);
  });

  testWidgets('6. Verified owner shows the Owner, Active and Verified badges', (
    tester,
  ) async {
    useDesktopScreen(tester);
    final services = fakeBackend({
      'GET /api/admin/users': {
        'users': [
          {
            'id': 1,
            'username': 'Frame',
            'phone': '0869370918',
            'role': 'owner',
            'status': 'active',
            'is_verified': 1,
            'created_at': '2026-11-17T10:00:00.000Z',
          },
        ],
      },
      'GET /api/admin/dormitories': {'dormitories': []},
    });

    await tester.pumpWidget(detail(services, 1));
    await tester.pumpAndSettle();

    expect(find.text('Owner'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('Verified owner'), findsOneWidget);
    expect(find.text('Yes'), findsOneWidget);
    expect(find.text('2026-11-17'), findsOneWidget);
  });

  testWidgets('7. Student has no Dorms section', (tester) async {
    useDesktopScreen(tester);
    final services = fakeBackend({
      'GET /api/admin/users': {
        'users': [student(status: 'active')],
      },
    });

    await tester.pumpWidget(detail(services, 7));
    await tester.pumpAndSettle();

    expect(find.text('beam'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
    expect(find.textContaining('Dorms ('), findsNothing);
  });

  testWidgets('8. Admin account cannot be suspended', (tester) async {
    useDesktopScreen(tester);
    final services = fakeBackend({
      'GET /api/admin/users': {
        'users': [
          {
            'id': 1,
            'username': 'admin',
            'phone': '0800000000',
            'role': 'admin',
            'status': 'active',
            'created_at': '2026-11-01T10:00:00.000Z',
          },
        ],
      },
    });

    await tester.pumpWidget(detail(services, 1));
    await tester.pumpAndSettle();

    expect(
      find.text('Admin accounts cannot be suspended from here.'),
      findsOneWidget,
    );
    expect(find.text('Suspend account'), findsNothing);
  });
}

Map<String, dynamic> student({required String status, String? reason}) => {
  'id': 7,
  'username': 'beam',
  'phone': '0861112222',
  'role': 'student',
  'status': status,
  'is_verified': 0,
  'created_at': '2026-11-01T10:00:00.000Z',
  'suspension_reason': reason,
  'suspended_at': reason == null ? null : '2026-11-12T08:30:00.000Z',
};
