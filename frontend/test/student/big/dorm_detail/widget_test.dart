// ผู้รับผิดชอบ: Big (นักศึกษา)
// widget test: หน้ารายละเอียดหอพักและหน้าเขียนรีวิว
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/modules/student/dorm_detail/view/student_dorm_detail_screen.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/fake_backend.dart';
import '../../../helpers/student_data.dart';

final review = {
  'id': 5,
  'rating': 5,
  'body': 'Very clean and quiet',
  'created_at': '2026-11-10',
};

FakeServices backend({
  List<Map<String, dynamic>> reviews = const [],
  List<http.Request>? requests,
}) => fakeBackend({
  'GET /api/dormitories/1': {
    'dormitory': dormJson(description: 'Close to the front gate'),
  },
  'GET /api/dormitories/1/reviews': {'reviews': reviews},
  'GET /api/favorites': {'favorites': []},
  'POST /api/favorites/1': {'ok': true},
  'POST /api/dormitories/1/reviews': {'ok': true},
}, requests: requests);

Future<void> openDetail(WidgetTester tester, AppServices services) async {
  useDesktopScreen(tester);
  // จอสูงพอให้เห็นส่วนรีวิวทั้งหมด ไม่ถูกแถบปุ่ม Call / Chat ด้านล่างบัง
  tester.view.physicalSize = const Size(1600, 2600);
  await tester.pumpWidget(
    MaterialApp(
      home: StudentDormDetailScreen(services: services, dormitoryId: 1),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('1. Detail shows the dorm name, description and free rooms', (
    tester,
  ) async {
    await openDetail(tester, backend());

    expect(find.text('Sunrise Dorm'), findsWidgets);
    expect(find.textContaining('Close to the front gate'), findsOneWidget);
    expect(find.text('2 of 10 rooms free'), findsOneWidget);
  });

  testWidgets('2. Published reviews are listed with the count', (tester) async {
    await openDetail(tester, backend(reviews: [review]));

    expect(find.text('Reviews (1)'), findsOneWidget);
    expect(find.text('Very clean and quiet'), findsOneWidget);
  });

  testWidgets('3. Dorm without reviews says so', (tester) async {
    await openDetail(tester, backend());

    expect(find.text('Reviews (0)'), findsOneWidget);
    expect(
      find.text('No reviews yet'),
      findsWidgets,
    ); // ทั้งในส่วนคะแนนและส่วนรีวิว
  });

  testWidgets('4. Heart button saves the dorm to favorites', (tester) async {
    final requests = <http.Request>[];
    await openDetail(tester, backend(requests: requests));

    await tester.tap(find.byTooltip('Save to favorites'));
    await tester.pumpAndSettle();

    expect(
      requests.where((r) => r.method == 'POST').single.url.path,
      '/api/favorites/1',
    );
    expect(find.text('Saved to favorites'), findsOneWidget);
    expect(find.byTooltip('Remove from favorites'), findsOneWidget);
  });

  testWidgets('5. Write a review sends the stars and the comment', (
    tester,
  ) async {
    final requests = <http.Request>[];
    await openDetail(tester, backend(requests: requests));

    await tester.ensureVisible(find.text('Write a review'));
    await tester.tap(find.text('Write a review'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('4 stars'));
    await tester.enterText(find.byType(TextField), 'Nice owner');
    await tester.tap(find.text('Submit review'));
    await tester.pumpAndSettle();

    final post = requests.where((r) => r.method == 'POST').single;
    expect(post.url.path, '/api/dormitories/1/reviews');
    expect(jsonDecode(post.body), {'rating': 4, 'body': 'Nice owner'});
    expect(
      find.text('Review sent. It will show after an admin checks it.'),
      findsOneWidget,
    );
  });

  testWidgets('6. Unknown dorm shows Dorm not found', (tester) async {
    await openDetail(tester, fakeBackend({}));

    expect(find.text('Dorm not found'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}
