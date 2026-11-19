// ผู้รับผิดชอบ: Kren (เจ้าของหอ)
// widget test: หน้ายืนยันตัวตนเจ้าของหอ
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/modules/owner/verification/view/verification_screen.dart';

import '../../../helpers/fake_backend.dart';
import '../../../helpers/owner_data.dart';

Future<void> openVerification(
  WidgetTester tester,
  AppServices services, {
  bool gate = false,
}) async {
  useDesktopScreen(tester);
  await tester.pumpWidget(
    MaterialApp(
      home: VerificationScreen(services: services, gate: gate),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('1. No document yet shows the upload form', (tester) async {
    await openVerification(tester, fakeBackend(ownerRoutes()));

    expect(find.text('No document sent yet'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
    expect(find.text('Send document'), findsOneWidget);
  });

  testWidgets('2. Sending without a file asks to choose one first', (
    tester,
  ) async {
    await openVerification(tester, fakeBackend(ownerRoutes()));

    final send = find.text('Send document');
    await tester.ensureVisible(send);
    await tester.tap(send);
    await tester.pumpAndSettle();

    expect(find.text('Please choose a document first'), findsOneWidget);
  });

  testWidgets('3. A pending document hides the upload form', (tester) async {
    await openVerification(
      tester,
      fakeBackend(
        ownerRoutes(
          verification: {
            'status': 'pending',
            'document_url': '/uploads/doc.pdf',
          },
        ),
      ),
    );

    expect(find.text('Pending review'), findsOneWidget);
    expect(find.text('Send document'), findsNothing);
  });

  testWidgets('4. Rejected shows the reason and allows sending again', (
    tester,
  ) async {
    await openVerification(
      tester,
      fakeBackend(
        ownerRoutes(
          verification: {
            'status': 'rejected',
            'document_url': '/uploads/doc.pdf',
            'rejection_reason': 'Photo is blurry',
          },
        ),
      ),
    );

    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('Reason: Photo is blurry'), findsOneWidget);
    expect(find.text('Send document'), findsOneWidget);
  });

  testWidgets('5. Gate mode explains why and offers Log out', (tester) async {
    await openVerification(tester, fakeBackend(ownerRoutes()), gate: true);

    expect(
      find.text(
        'You must verify your identity as a dorm owner before using the app.',
      ),
      findsOneWidget,
    );
    expect(find.text('Log out'), findsOneWidget);
  });
}
