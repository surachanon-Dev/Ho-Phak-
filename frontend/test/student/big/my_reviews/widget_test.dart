// ผู้รับผิดชอบ: Big (นักศึกษา)
// widget test: หน้ารีวิวของฉัน
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/modules/student/my_reviews/view/my_reviews_screen.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/fake_backend.dart';
import '../../../helpers/student_data.dart';

Future<void> openMyReviews(WidgetTester tester, AppServices services) async {
  useDesktopScreen(tester);
  await tester.pumpWidget(
    MaterialApp(home: MyReviewsScreen(services: services, myUserId: 9)),
  );
  await tester.pumpAndSettle();
}

FakeServices backend({List<http.Request>? requests}) => fakeBackend({
  'GET /api/reviews/me': {
    'reviews': [myReviewJson(id: 1, dorm: 'Sunrise Dorm')],
  },
  'DELETE /api/reviews/1': {'ok': true},
  'PUT /api/reviews/1': {'ok': true},
}, requests: requests);

void main() {
  testWidgets('1. Each review shows its status and the admin reason', (
    tester,
  ) async {
    await openMyReviews(
      tester,
      fakeBackend({
        'GET /api/reviews/me': {
          'reviews': [
            myReviewJson(id: 2, dorm: 'Shown Dorm', status: 'published'),
            myReviewJson(
              id: 3,
              dorm: 'Hidden Dorm',
              status: 'hidden',
              reason: 'Contains a phone number',
            ),
          ],
        },
      }),
    );

    expect(find.text('My reviews'), findsOneWidget);
    expect(find.text('Waiting for admin'), findsNothing);
    expect(find.text('Published'), findsOneWidget);
    expect(find.text('Hidden by admin'), findsOneWidget);
    expect(find.textContaining('Contains a phone number'), findsOneWidget);
  });

  testWidgets('2. No reviews shows an empty message', (tester) async {
    await openMyReviews(
      tester,
      fakeBackend({
        'GET /api/reviews/me': {'reviews': []},
      }),
    );

    expect(find.text('No reviews yet'), findsOneWidget);
  });

  testWidgets('3. Delete asks first, then removes the review', (tester) async {
    final requests = <http.Request>[];
    await openMyReviews(tester, backend(requests: requests));

    await tester.tap(find.byTooltip('Review options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this review?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(
      requests.where((r) => r.method == 'DELETE').single.url.path,
      '/api/reviews/1',
    );
    expect(find.text('Review deleted'), findsOneWidget);
  });

  testWidgets('4. Edit sends the new rating to the backend', (tester) async {
    final requests = <http.Request>[];
    await openMyReviews(tester, backend(requests: requests));

    await tester.tap(find.byTooltip('Review options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.text('Edit review'), findsOneWidget);
    await tester.tap(find.byTooltip('5 stars'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    final put = requests.where((r) => r.method == 'PUT').single;
    expect(put.url.path, '/api/reviews/1');
    expect(jsonDecode(put.body)['rating'], 5);
  });
}
