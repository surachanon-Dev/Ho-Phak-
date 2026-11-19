// ผู้รับผิดชอบ: Kren (เจ้าของหอ)
// widget test: หน้ารีวิวของหอทั้งหมดของเจ้าของ
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/modules/owner/my_reviews/view/my_reviews_screen.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/fake_backend.dart';
import '../../../helpers/owner_data.dart';

Future<void> openReviews(WidgetTester tester, AppServices services) async {
  useDesktopScreen(tester);
  await tester.pumpWidget(
    MaterialApp(home: MyReviewsScreen(services: services)),
  );
  await tester.pumpAndSettle();
}

/// หอ 2 หอ หอละ 1 รีวิว
Map<String, Object> twoDorms({Map<String, Object> extra = const {}}) =>
    ownerRoutes(
      dorms: [
        ownerDormJson(id: 1, name: 'Baan Suan'),
        ownerDormJson(id: 2, name: 'Baan Rim'),
      ],
      reviews: {
        1: [ownerReviewJson(id: 1, rating: 5, body: 'Great place')],
        2: [ownerReviewJson(id: 2, rating: 3, body: 'Noisy at night')],
      },
      extra: extra,
    );

void main() {
  testWidgets('1. Reviews from every dorm and the average are shown', (
    tester,
  ) async {
    await openReviews(tester, fakeBackend(twoDorms()));

    expect(find.text('My reviews'), findsOneWidget);
    expect(find.text('Great place'), findsOneWidget);
    expect(find.text('Noisy at night'), findsOneWidget);
    expect(find.text('4.0'), findsOneWidget);
    expect(find.textContaining('2 reviews'), findsOneWidget);
  });

  testWidgets('2. Choosing a dorm shows only its reviews', (tester) async {
    await openReviews(tester, fakeBackend(twoDorms()));

    await tester.tap(find.widgetWithText(InkWell, 'Baan Rim').first);
    await tester.pumpAndSettle();

    expect(find.text('Noisy at night'), findsOneWidget);
    expect(find.text('Great place'), findsNothing);
  });

  testWidgets('3. No reviews shows the empty message', (tester) async {
    await openReviews(
      tester,
      fakeBackend(ownerRoutes(dorms: [ownerDormJson(id: 1)])),
    );

    expect(find.text('No published reviews yet'), findsOneWidget);
  });

  testWidgets('4. Report needs a reason and then sends it to admin', (
    tester,
  ) async {
    final requests = <http.Request>[];
    // หลังส่ง report หน้าจอจะโหลดรายการ report ใหม่ จึงให้คำตอบเปลี่ยนตามสถานะ
    final reports = <Map<String, dynamic>>[];
    await openReviews(
      tester,
      fakeBackend(
        ownerRoutes(
          dorms: [ownerDormJson(id: 1)],
          reviews: {
            1: [ownerReviewJson(id: 1, body: 'Great place')],
          },
          extra: {
            'GET /api/owner/review-reports': () => {'reports': reports},
            'POST /api/owner/reviews/1/report': () {
              reports.add({'review_id': 1, 'reason': 'This is spam'});
              return {'ok': true};
            },
          },
        ),
        requests: requests,
      ),
    );

    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();
    expect(find.text('Report this review?'), findsOneWidget);

    FilledButton send() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Send report'),
    );
    expect(send().onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'This is spam');
    await tester.pump();
    expect(send().onPressed, isNotNull);

    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();

    final report = requests.singleWhere((r) => r.method == 'POST');
    expect(report.url.path, '/api/owner/reviews/1/report');
    expect(report.body, contains('This is spam'));
    expect(find.text('Report sent. Admin will check it.'), findsOneWidget);
    expect(find.text('Reported · waiting for admin'), findsOneWidget);
  });
}
