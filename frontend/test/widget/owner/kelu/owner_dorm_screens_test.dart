// เทสต์ widget ของหน้าหอพักฝั่ง owner: Dashboard, Dormitory detail, Dormitory form, Location picker
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/owner/dashboard/dashboard_screen.dart';
import 'package:hopak_frontend/features/owner/dorm_detail/dormitory_detail_screen.dart';
import 'package:hopak_frontend/features/owner/dorm_form/dormitory_form_screen.dart';
import 'package:hopak_frontend/features/owner/dorm_form/location_picker_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'owner_test_helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Dashboard', () {
    testWidgets('1. shows my dorms with zone and price', (tester) async {
      final services = ownerServicesWith(
        ownerApi(
          dorms: [
            dormJson(id: 1, name: 'Baan Suan', price: 3200),
            dormJson(id: 2, name: 'Baan Rim', price: 4500, status: 'pending'),
          ],
        ),
      );
      await tester.pumpWidget(
        MaterialApp(home: DashboardScreen(services: services)),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Dorms'), findsOneWidget);
      expect(find.text('Baan Suan'), findsOneWidget);
      expect(find.text('Baan Rim'), findsOneWidget);
      expect(find.textContaining('3,200 THB/month'), findsOneWidget);
      expect(find.textContaining('4,500 THB/month'), findsOneWidget);
      expect(find.text('Total dorms'), findsOneWidget);
    });

    testWidgets('2. no dorms shows the empty state', (tester) async {
      final services = ownerServicesWith(ownerApi());
      await tester.pumpWidget(
        MaterialApp(home: DashboardScreen(services: services)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add your first dorm'), findsOneWidget);
    });
  });

  group('Dormitory detail', () {
    testWidgets('3. shows the dorm info and edit/delete actions', (
      tester,
    ) async {
      final services = ownerServicesWith(
        ownerApi(
          dorms: [dormJson(id: 1, name: 'Baan Suan', total: 10, available: 4)],
          reviews: {
            1: [reviewJson(rating: 5), reviewJson(id: 2, rating: 3)],
          },
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: DormitoryDetailScreen(services: services, dormitoryId: 1),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Baan Suan'), findsWidgets);
      expect(find.text('Total rooms'), findsOneWidget);
      expect(find.text('Available now'), findsOneWidget);
      expect(find.text('Edit dorm'), findsOneWidget);
      expect(find.text('Delete dorm'), findsOneWidget);
    });

    testWidgets('4. unknown dorm shows "Dorm not found"', (tester) async {
      final services = ownerServicesWith(ownerApi());
      await tester.pumpWidget(
        MaterialApp(
          home: DormitoryDetailScreen(services: services, dormitoryId: 99),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dorm not found'), findsOneWidget);
    });
  });

  group('Dormitory form', () {
    testWidgets('5. submitting an empty form shows required errors', (
      tester,
    ) async {
      final services = ownerServicesWith(ownerApi());
      await tester.pumpWidget(
        MaterialApp(home: DormitoryFormScreen(services: services)),
      );
      await tester.pumpAndSettle();

      final submit = find.text('Submit for review');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(find.text('This field is required'), findsWidgets);
    });
  });

  group('Location picker', () {
    testWidgets('6. opens with the title', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LocationPickerScreen()));
      await tester.pump();

      expect(find.text('Set dorm location'), findsOneWidget);
    });
  });
}
