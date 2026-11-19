// ผู้รับผิดชอบ: Kren (เจ้าของหอ)
// widget test: โครงหลักของเจ้าของหอ (OwnerShell)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/model/user.dart';
import 'package:hopak_frontend/modules/owner/shell/view/owner_shell.dart';
import 'package:hopak_frontend/modules/owner/verification/view/verification_screen.dart';

import '../../../helpers/fake_backend.dart';
import '../../../helpers/owner_data.dart';

/// เปิด shell บนจอมือถือ (ใช้แถบเมนูล่าง NavigationBar)
Future<void> openShell(
  WidgetTester tester,
  AppServices services,
  CurrentUser user,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(420, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: OwnerShell(services: services, user: user),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('1. A verified owner sees three tabs and My Dorms first', (
    tester,
  ) async {
    await openShell(
      tester,
      fakeBackend(ownerRoutes(dorms: [ownerDormJson(name: 'Baan Suan')])),
      ownerUser(),
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('My Dorms'), findsWidgets);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Baan Suan'), findsOneWidget);
  });

  testWidgets('2. Tapping Profile switches to the profile tab', (tester) async {
    await openShell(tester, fakeBackend(ownerRoutes()), ownerUser());

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

  testWidgets('3. A wide screen uses the side rail instead', (tester) async {
    useDesktopScreen(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: OwnerShell(
          services: fakeBackend(ownerRoutes()),
          user: ownerUser(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('4. An unverified owner only sees the verification gate', (
    tester,
  ) async {
    await openShell(
      tester,
      fakeBackend(ownerRoutes()),
      ownerUser(verified: false),
    );

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(VerificationScreen), findsOneWidget);
  });
}
