// ผู้รับผิดชอบ: Kren (เจ้าของหอ)
// widget test: หน้าโปรไฟล์และหน้าแก้ไขโปรไฟล์ของเจ้าของหอ
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/model/owner_profile.dart';
import 'package:hopak_frontend/modules/owner/profile/view/edit_profile_screen.dart';
import 'package:hopak_frontend/modules/owner/profile/view/profile_screen.dart';

import '../../../helpers/fake_backend.dart';
import '../../../helpers/owner_data.dart';

Future<void> openProfile(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 1600);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ProfileScreen(
          services: fakeBackend(ownerRoutes()),
          user: ownerUser(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const profile = OwnerProfile(
  firstName: 'Somchai',
  surname: 'Jaidee',
  phone: '0812345678',
);

void main() {
  testWidgets('1. Profile shows every menu row', (tester) async {
    await openProfile(tester);

    for (final label in [
      'Edit profile',
      'Change password',
      'My verification',
      'My reviews',
      'Notification settings',
      'Help / Contact admin',
      'Sign out',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('2. Sign out asks for confirmation and can be cancelled', (
    tester,
  ) async {
    await openProfile(tester);

    final signOut = find.text('Sign out');
    await tester.ensureVisible(signOut);
    await tester.tap(signOut);
    await tester.pumpAndSettle();
    expect(find.text('Sign out?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out?'), findsNothing);
    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('3. Edit profile enables Save only after a change', (
    tester,
  ) async {
    useDesktopScreen(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: EditProfileScreen(
          services: fakeBackend(ownerRoutes()),
          profile: profile,
        ),
      ),
    );
    FilledButton save() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save changes'),
    );
    expect(save().onPressed, isNull);

    await tester.enterText(find.byType(TextFormField).at(0), 'Somchai2');
    await tester.pump();

    expect(save().onPressed, isNotNull);
  });

  testWidgets('4. Changing the phone number asks for the password', (
    tester,
  ) async {
    useDesktopScreen(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: EditProfileScreen(
          services: fakeBackend(ownerRoutes()),
          profile: profile,
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(2), '0819990000');
    await tester.pump();
    final save = find.widgetWithText(FilledButton, 'Save changes');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();

    expect(
      find.text('Enter your password to change your phone number'),
      findsOneWidget,
    );
  });
}
