// Widget Test: student search page (lib/views/student/search_view.dart)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hophak_frontend/mock/mock_db.dart';
import 'package:hophak_frontend/views/student/search_view.dart';
import 'package:hophak_frontend/views/widgets/dorm_card.dart';

import '../helpers/test_app.dart';

void main() {
  final db = MockDb.instance;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db.currentUserId = 3; // Frame (student)
  });

  Iterable<Map<String, dynamic>> published() => db.dormitories.where((d) => d['status'] == 'published');

  Future<void> openSearch(WidgetTester tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(inScaffold(const SearchView()));
    await settle(tester);
  }

  Future<void> typeAndSearch(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField).first, text);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settle(tester);
  }

  testWidgets('WID-37 shows every published dorm and the result count', (tester) async {
    await openSearch(tester);
    expect(find.text('พบ ${published().length} หอพัก'), findsOneWidget);
    expect(find.byType(DormCard), findsWidgets);
  });

  testWidgets('WID-38 dorms that are not published are never shown', (tester) async {
    await openSearch(tester);
    final hidden = db.dormitories.where((d) => d['status'] != 'published').map((d) => d['name'] as String);
    final shown = tester.widgetList<DormCard>(find.byType(DormCard)).map((c) => c.dorm.name).toSet();
    for (final name in hidden) {
      if (published().any((d) => d['name'] == name)) continue; // same name used by a published dorm
      expect(shown.contains(name), isFalse, reason: '"$name" is not published but is shown');
    }
  });

  testWidgets('WID-39 zone chip "หลังมอ" shows only dorms in หลังมอ', (tester) async {
    await openSearch(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'หลังมอ'));
    await settle(tester);
    final expected = published().where((d) => d['zone'] == 'หลังมอ').length;
    expect(find.text('พบ $expected หอพัก'), findsOneWidget);
    for (final c in tester.widgetList<DormCard>(find.byType(DormCard))) {
      expect(c.dorm.zone, 'หลังมอ');
    }
  });

  testWidgets('WID-40 "ทุกโซน" brings every dorm back', (tester) async {
    await openSearch(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'หลังมอ'));
    await settle(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'ทุกโซน'));
    await settle(tester);
    expect(find.text('พบ ${published().length} หอพัก'), findsOneWidget);
  });

  testWidgets('WID-41 searching by name finds that dorm', (tester) async {
    await openSearch(tester);
    final name = published().first['name'] as String;
    await typeAndSearch(tester, name);
    expect(tester.widgetList<DormCard>(find.byType(DormCard)).map((c) => c.dorm.name), contains(name));
  });

  testWidgets('WID-42 a keyword with no match shows the empty message', (tester) async {
    await openSearch(tester);
    await typeAndSearch(tester, 'zzzz-ไม่มีหอนี้');
    expect(find.text('พบ 0 หอพัก'), findsOneWidget);
    expect(find.text('ไม่พบหอพักที่ตรงกับเงื่อนไข'), findsOneWidget);
  });

  testWidgets('WID-43 sort "ราคาต่ำ-สูง" puts the cheapest dorm first', (tester) async {
    await openSearch(tester);
    await tester.tap(find.text('ล่าสุด'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ราคาต่ำ-สูง').last);
    await settle(tester);
    final prices = tester.widgetList<DormCard>(find.byType(DormCard)).map((c) => c.dorm.pricePerMonth).toList();
    expect(prices, [...prices]..sort());
  });
}
