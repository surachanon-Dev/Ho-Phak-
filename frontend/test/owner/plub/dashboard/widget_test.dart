// ผู้รับผิดชอบ: Plub (เจ้าของหอ)
// widget test: หน้า Dashboard (My Dorms) ของเจ้าของหอ
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/modules/owner/dashboard/view/dashboard_screen.dart';
import 'package:hopak_frontend/modules/owner/dorm_detail/view/dormitory_detail_screen.dart';
import 'package:hopak_frontend/modules/owner/dorm_form/view/dormitory_form_screen.dart';

import '../../../helpers/fake_backend.dart';
import '../../../helpers/owner_data.dart';

Future<void> openDashboard(WidgetTester tester, AppServices services) async {
  useDesktopScreen(tester);
  await tester.pumpWidget(
    MaterialApp(home: DashboardScreen(services: services)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('1. My dorms are listed with their price', (tester) async {
    await openDashboard(
      tester,
      fakeBackend(
        ownerRoutes(
          dorms: [
            ownerDormJson(id: 1, name: 'Baan Suan', price: 3200),
            ownerDormJson(
              id: 2,
              name: 'Baan Rim',
              price: 4500,
              status: 'pending',
            ),
          ],
        ),
      ),
    );

    expect(find.text('My Dorms'), findsWidgets);
    expect(find.text('Baan Suan'), findsOneWidget);
    expect(find.text('Baan Rim'), findsOneWidget);
    expect(find.textContaining('3,200'), findsOneWidget);
    expect(find.textContaining('4,500'), findsOneWidget);
    expect(find.text('Total dorms'), findsOneWidget);
  });

  testWidgets('2. No dorms shows the Add your first dorm state', (
    tester,
  ) async {
    await openDashboard(tester, fakeBackend(ownerRoutes()));

    expect(find.text('Add your first dorm'), findsOneWidget);
  });

  testWidgets('3. Tapping a dorm opens its detail page', (tester) async {
    await openDashboard(
      tester,
      fakeBackend(ownerRoutes(dorms: [ownerDormJson(id: 1)])),
    );

    await tester.tap(find.text('Baan Suan'));
    await tester.pumpAndSettle();

    expect(find.byType(DormitoryDetailScreen), findsOneWidget);
  });

  testWidgets('4. Add dorm opens the dorm form', (tester) async {
    await openDashboard(
      tester,
      fakeBackend(ownerRoutes(dorms: [ownerDormJson(id: 1)])),
    );

    await tester.tap(find.text('Add dorm').first);
    await tester.pumpAndSettle();

    expect(find.byType(DormitoryFormScreen), findsOneWidget);
  });
}
