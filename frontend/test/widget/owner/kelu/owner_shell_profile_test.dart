// เทสต์ widget ของโครงหลัก (OwnerShell) และหน้าโปรไฟล์ฝั่ง owner
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/owner/owner_shell.dart';
import 'package:hopak_frontend/features/owner/profile/profile_screen.dart';
import 'package:hopak_frontend/shared/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/admin_test_helpers.dart' show setScreenSize;
import 'owner_test_helpers.dart';

CurrentUser _owner({bool verified = true}) => CurrentUser(
  id: 7,
  role: 'owner',
  status: 'active',
  isVerified: verified,
  username: 'somchai',
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Owner shell', () {
    testWidgets('1. verified owner sees the three tabs on My Dorms', (
      tester,
    ) async {
      final services = ownerServicesWith(
        ownerApi(dorms: [dormJson(id: 1, name: 'Baan Suan')]),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: OwnerShell(services: services, user: _owner()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('My Dorms'), findsWidgets);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Baan Suan'), findsOneWidget);
    });

    testWidgets('2. tapping Profile switches the tab', (tester) async {
      final services = ownerServicesWith(ownerApi());
      await tester.pumpWidget(
        MaterialApp(
          home: OwnerShell(services: services, user: _owner()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Profile'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        2,
      );
      expect(find.text('Edit profile'), findsOneWidget);
    });

    testWidgets('3. unverified owner is sent to the verification gate', (
      tester,
    ) async {
      final services = ownerServicesWith(ownerApi());
      await tester.pumpWidget(
        MaterialApp(
          home: OwnerShell(services: services, user: _owner(verified: false)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Verification'), findsOneWidget);
    });
  });

  group('Profile', () {
    testWidgets('4. shows every menu row', (tester) async {
      setScreenSize(tester, const Size(800, 1600));
      final services = ownerServicesWith(ownerApi());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileScreen(services: services, user: _owner()),
          ),
        ),
      );
      await tester.pumpAndSettle();

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

    testWidgets('5. Sign out asks for confirmation and can be cancelled', (
      tester,
    ) async {
      setScreenSize(tester, const Size(800, 1600));
      final services = ownerServicesWith(ownerApi());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileScreen(services: services, user: _owner()),
          ),
        ),
      );
      await tester.pumpAndSettle();

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
  });
}
