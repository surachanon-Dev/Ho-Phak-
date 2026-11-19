// ผู้รับผิดชอบ: Plub (Tester)
// ทดสอบ: ตัวกรองในหน้าค้นหาหอพัก (ราคา, ห้องว่าง, สิ่งอำนวยความสะดวก)
// Run: flutter test test/widgets/search_filters_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/modules/student/search/view/search_screen.dart';
import 'package:http/http.dart' as http;

import '../helpers/fake_backend.dart';
import '../helpers/student_data.dart';

const amenities = {
  'amenities': [
    {'id': 1, 'name': 'Wi-Fi'},
    {'id': 4, 'name': 'Air conditioner'},
    {'id': 6, 'name': 'Parking'},
  ],
};

void main() {
  /// query ของการค้นหาครั้งล่าสุด
  Map<String, String> lastSearch(List<http.Request> r) =>
      r.where((x) => x.url.path == '/api/dormitories').last.url.queryParameters;

  Future<void> openSearch(WidgetTester tester, Map<String, Object> routes, List<http.Request> requests) async {
    useDesktopScreen(tester);
    await tester.pumpWidget(MaterialApp(home: SearchScreen(services: fakeBackend(routes, requests: requests))));
    await tester.pumpAndSettle();
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Filters'));
    await tester.pumpAndSettle();
  }

  final routes = <String, Object>{
    'GET /api/dormitories': {'dormitories': [dormJson(name: 'Sunrise Dorm')]},
    'GET /api/amenities': amenities,
  };

  testWidgets('FILTER-01 ตัวกรองแสดงช่องราคา สวิตช์ห้องว่าง และชิปสิ่งอำนวยความสะดวกทุกตัว', (tester) async {
    await openSearch(tester, routes, []);
    await openSheet(tester);
    expect(find.text('Filters'), findsWidgets);
    expect(find.text('Monthly rent (baht)'), findsOneWidget);
    expect(find.text('Only dorms with free rooms'), findsOneWidget);
    expect(find.text('Amenities'), findsOneWidget);
    for (final name in ['Wi-Fi', 'Air conditioner', 'Parking']) {
      expect(find.widgetWithText(FilterChip, name), findsOneWidget);
    }
  });

  testWidgets('FILTER-02 เลือกสิ่งอำนวยความสะดวกแล้วกด Apply ส่ง amenities=1,6 ไปค้นหา', (tester) async {
    final requests = <http.Request>[];
    await openSearch(tester, routes, requests);
    await openSheet(tester);
    await tester.tap(find.widgetWithText(FilterChip, 'Parking'));
    await tester.tap(find.widgetWithText(FilterChip, 'Wi-Fi'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();

    expect(lastSearch(requests)['amenities'], '1,6');
  });

  testWidgets('FILTER-03 ส่งราคาและห้องว่างพร้อมกับสิ่งอำนวยความสะดวก', (tester) async {
    final requests = <http.Request>[];
    await openSearch(tester, routes, requests);
    await openSheet(tester);
    final boxes = find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField));
    await tester.enterText(boxes.at(0), '2000');
    await tester.enterText(boxes.at(1), '4000');
    await tester.tap(find.byType(Switch));
    await tester.tap(find.widgetWithText(FilterChip, 'Air conditioner'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();

    final q = lastSearch(requests);
    expect(q['minPrice'], '2000');
    expect(q['maxPrice'], '4000');
    expect(q['hasRooms'], '1');
    expect(q['amenities'], '4');
  });

  testWidgets('FILTER-04 ไม่เลือกสิ่งอำนวยความสะดวก ไม่ส่ง amenities', (tester) async {
    final requests = <http.Request>[];
    await openSearch(tester, routes, requests);
    await openSheet(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();
    expect(lastSearch(requests).containsKey('amenities'), isFalse);
  });

  testWidgets('FILTER-05 เปิดตัวกรองอีกครั้ง ชิปที่เลือกไว้ยังถูกเลือกอยู่ และ Reset ล้างทั้งหมด', (tester) async {
    final requests = <http.Request>[];
    await openSearch(tester, routes, requests);
    await openSheet(tester);
    await tester.tap(find.widgetWithText(FilterChip, 'Wi-Fi'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();

    await openSheet(tester);
    expect(tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Wi-Fi')).selected, isTrue);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Reset'));
    await tester.pumpAndSettle();
    expect(lastSearch(requests).containsKey('amenities'), isFalse);
  });

  testWidgets('FILTER-06 โหลดรายการสิ่งอำนวยความสะดวกไม่ได้ ซ่อนส่วนนี้ และตัวกรองอื่นยังใช้ได้', (tester) async {
    final requests = <http.Request>[];
    await openSearch(tester, {'GET /api/dormitories': {'dormitories': []}}, requests);
    await openSheet(tester);
    expect(find.text('Amenities'), findsNothing);
    expect(find.byType(FilterChip), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();
    expect(requests.where((r) => r.url.path == '/api/dormitories'), hasLength(2));
  });
}
