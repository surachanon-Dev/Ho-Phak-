// ผู้รับผิดชอบ: Karn (นักศึกษา)
// widget test: หน้าโปรไฟล์นักศึกษา
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/modules/student/profile/view/student_profile_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_backend.dart';

FakeServices backend({List<http.Request>? requests}) => fakeBackend({
  'GET /api/me/profile': {
    'profile': {
      'first_name': 'Karn',
      'surname': 'Student',
      'phone': '0812345678',
    },
  },
  'POST /api/me/become-owner': {'ok': true},
  'GET /api/me': {
    'user': {'id': 9, 'role': 'owner', 'status': 'active', 'is_verified': 0},
  },
  'POST /api/auth/logout': {'ok': true},
}, requests: requests);

Future<void> openProfile(WidgetTester tester, AppServices services) async {
  useDesktopScreen(tester);
  tester.view.physicalSize = const Size(1200, 2000); // เห็นเมนูครบไม่ต้องเลื่อน
  await tester.pumpWidget(
    MaterialApp(
      home: StudentProfileScreen(services: services, user: fakeUser()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('1. Profile shows the name, the Student badge and the menu', (
    tester,
  ) async {
    await openProfile(tester, backend());

    expect(find.text('Karn Student'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
    for (final item in [
      'Edit profile',
      'Change password',
      'My reviews',
      'Become a dorm owner',
      'Log out',
    ]) {
      expect(find.text(item), findsOneWidget);
    }
  });

  testWidgets('2. Contact admin opens a dialog', (tester) async {
    await openProfile(tester, backend());

    await tester.tap(find.text('Contact admin'));
    await tester.pumpAndSettle();

    expect(
      find.text('Admin phone and email have not been set yet.'),
      findsOneWidget,
    );
  });

  testWidgets('3. Become a dorm owner asks first, then calls the backend', (
    tester,
  ) async {
    final requests = <http.Request>[];
    await openProfile(tester, backend(requests: requests));

    await tester.tap(find.text('Become a dorm owner'));
    await tester.pumpAndSettle();
    expect(find.text('Become a dorm owner?'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(
      requests.map((r) => '${r.method} ${r.url.path}'),
      containsAllInOrder(['POST /api/me/become-owner', 'GET /api/me']),
    );
    // บัญชีเปลี่ยนเป็นเจ้าของแล้ว แอปพาออกจากหน้าโปรไฟล์นักศึกษา
    expect(find.text('Become a dorm owner'), findsNothing);
  });

  testWidgets('4. Log out asks first and can be cancelled', (tester) async {
    final requests = <http.Request>[];
    await openProfile(tester, backend(requests: requests));

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Log out?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Log out?'), findsNothing);
    expect(
      requests.map((r) => r.url.path),
      isNot(contains('/api/auth/logout')),
    );
  });
}
