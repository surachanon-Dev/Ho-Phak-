// ผู้รับผิดชอบ: Big (นักศึกษา)
// widget test: หน้าหลักนักศึกษา
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/modules/student/home/view/student_home_screen.dart';

import '../../../helpers/fake_backend.dart';
import '../../../helpers/student_data.dart';

Future<void> openHome(
  WidgetTester tester,
  AppServices services, {
  OpenSearch? onOpenSearch,
}) async {
  useDesktopScreen(tester);
  await tester.pumpWidget(
    MaterialApp(
      home: StudentHomeScreen(
        services: services,
        user: fakeUser(username: 'Big'),
        onOpenSearch: onOpenSearch,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('1. Home greets the student and lists published dorms', (
    tester,
  ) async {
    await openHome(
      tester,
      fakeBackend({
        'GET /api/dormitories': {
          'dormitories': [
            dormJson(name: 'Sunrise Dorm', rating: 4.5, reviewCount: 3),
          ],
        },
      }),
    );

    expect(find.text('Hello, Big'), findsOneWidget);
    expect(find.text('Sunrise Dorm'), findsWidgets);
    // หอที่มีรีวิวจะขึ้นในส่วน Recommended (คะแนนสูงสุด)
    expect(find.text('Recommended'), findsOneWidget);
  });

  testWidgets('2. No published dorms shows an empty message', (tester) async {
    await openHome(
      tester,
      fakeBackend({
        'GET /api/dormitories': {'dormitories': []},
      }),
    );

    expect(find.text('No published dorms yet'), findsOneWidget);
  });

  testWidgets('3. Load error shows Try again, which loads the dorms again', (
    tester,
  ) async {
    var down = true;
    await openHome(
      tester,
      fakeBackend({
        'GET /api/dormitories': () => down
            ? {'dormitories': 'broken'} // ข้อมูลผิดรูป ทำให้โหลดไม่สำเร็จ
            : {
                'dormitories': [dormJson(name: 'Sunrise Dorm')],
              },
      }),
    );
    expect(find.text('Could not load dorms'), findsOneWidget);

    down = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Could not load dorms'), findsNothing);
    expect(find.text('Sunrise Dorm'), findsWidgets);
  });

  testWidgets('4. Tapping a zone opens search for that zone', (tester) async {
    final opened = <String?>[];
    await openHome(
      tester,
      fakeBackend({
        'GET /api/dormitories': {'dormitories': []},
      }),
      onOpenSearch: ({zone, sort}) => opened.add(zone),
    );

    await tester.tap(find.widgetWithText(ActionChip, 'Front gate'));
    await tester.pump();

    expect(opened, ['หน้ามอ']);
  });
}
