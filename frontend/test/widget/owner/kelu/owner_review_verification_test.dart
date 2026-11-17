// เทสต์ widget ของหน้ารีวิวและหน้ายืนยันตัวตนฝั่ง owner
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/owner/my_reviews/my_reviews_screen.dart';
import 'package:hopak_frontend/features/owner/verification/verification_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'owner_test_helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('My reviews', () {
    testWidgets('1. shows reviews from every dorm and the average', (
      tester,
    ) async {
      final services = ownerServicesWith(
        ownerApi(
          dorms: [
            dormJson(id: 1, name: 'Baan Suan'),
            dormJson(id: 2, name: 'Baan Rim'),
          ],
          reviews: {
            1: [reviewJson(id: 1, rating: 5, body: 'Great place')],
            2: [reviewJson(id: 2, rating: 3, body: 'Noisy at night')],
          },
        ),
      );
      await tester.pumpWidget(
        MaterialApp(home: MyReviewsScreen(services: services)),
      );
      await tester.pumpAndSettle();

      expect(find.text('My reviews'), findsOneWidget);
      expect(find.text('Great place'), findsOneWidget);
      expect(find.text('Noisy at night'), findsOneWidget);
      expect(find.text('4.0'), findsOneWidget);
      expect(find.textContaining('2 reviews'), findsOneWidget);
    });

    testWidgets('2. filter by dorm shows only that dorm reviews', (
      tester,
    ) async {
      final services = ownerServicesWith(
        ownerApi(
          dorms: [
            dormJson(id: 1, name: 'Baan Suan'),
            dormJson(id: 2, name: 'Baan Rim'),
          ],
          reviews: {
            1: [reviewJson(id: 1, body: 'Great place')],
            2: [reviewJson(id: 2, rating: 3, body: 'Noisy at night')],
          },
        ),
      );
      await tester.pumpWidget(
        MaterialApp(home: MyReviewsScreen(services: services)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(InkWell, 'Baan Rim').first);
      await tester.pumpAndSettle();

      expect(find.text('Noisy at night'), findsOneWidget);
      expect(find.text('Great place'), findsNothing);
    });

    testWidgets('3. no reviews shows the empty message', (tester) async {
      final services = ownerServicesWith(ownerApi(dorms: [dormJson(id: 1)]));
      await tester.pumpWidget(
        MaterialApp(home: MyReviewsScreen(services: services)),
      );
      await tester.pumpAndSettle();

      expect(find.text('No published reviews yet'), findsOneWidget);
    });

    testWidgets('4. report needs a reason before it can be sent', (
      tester,
    ) async {
      final services = ownerServicesWith(
        ownerApi(
          dorms: [dormJson(id: 1)],
          reviews: {
            1: [reviewJson(id: 1, body: 'Great place')],
          },
        ),
      );
      await tester.pumpWidget(
        MaterialApp(home: MyReviewsScreen(services: services)),
      );
      await tester.pumpAndSettle();

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
      expect(find.text('Report sent. Admin will check it.'), findsOneWidget);
      expect(find.text('Reported · waiting for admin'), findsOneWidget);
    });
  });

  group('Verification', () {
    testWidgets('5. no document yet shows the upload form', (tester) async {
      final services = ownerServicesWith(ownerApi());
      await tester.pumpWidget(
        MaterialApp(home: VerificationScreen(services: services)),
      );
      await tester.pumpAndSettle();

      expect(find.text('No document sent yet'), findsOneWidget);
      expect(find.byIcon(Icons.upload_file), findsOneWidget);
      expect(find.text('Send document'), findsOneWidget);
    });

    testWidgets('6. pending document hides the upload form', (tester) async {
      final services = ownerServicesWith(
        ownerApi(
          verification: {
            'status': 'pending',
            'document_url': '/uploads/doc.pdf',
          },
        ),
      );
      await tester.pumpWidget(
        MaterialApp(home: VerificationScreen(services: services)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pending review'), findsOneWidget);
      expect(find.text('Verification document sent'), findsOneWidget);
      expect(find.text('Send document'), findsNothing);
    });

    testWidgets('7. rejected shows the reason and allows sending again', (
      tester,
    ) async {
      final services = ownerServicesWith(
        ownerApi(
          verification: {
            'status': 'rejected',
            'document_url': '/uploads/doc.pdf',
            'rejection_reason': 'Photo is blurry',
          },
        ),
      );
      await tester.pumpWidget(
        MaterialApp(home: VerificationScreen(services: services)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rejected'), findsOneWidget);
      expect(find.text('Reason: Photo is blurry'), findsOneWidget);
      expect(find.text('Send document'), findsOneWidget);
    });

    testWidgets('8. gate mode explains why verification is required', (
      tester,
    ) async {
      final services = ownerServicesWith(ownerApi());
      await tester.pumpWidget(
        MaterialApp(home: VerificationScreen(services: services, gate: true)),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'You must verify your identity as a dorm owner before using the app.',
        ),
        findsOneWidget,
      );
      expect(find.text('Sign out'), findsOneWidget);
    });
  });
}
