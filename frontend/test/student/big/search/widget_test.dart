// ผู้รับผิดชอบ: Big (นักศึกษา)
// widget test: หน้าค้นหาหอพัก
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/modules/student/search/view/search_screen.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/fake_backend.dart';
import '../../../helpers/student_data.dart';

Future<void> openSearch(WidgetTester tester, AppServices services) async {
  useDesktopScreen(tester);
  await tester.pumpWidget(MaterialApp(home: SearchScreen(services: services)));
  await tester.pumpAndSettle();
}

/// query ของการค้นหาครั้งล่าสุด
Map<String, String> lastSearch(List<http.Request> requests) => requests
    .where((r) => r.url.path == '/api/dormitories')
    .last
    .url
    .queryParameters;

void main() {
  testWidgets('1. Search page lists the dorms found', (tester) async {
    await openSearch(
      tester,
      fakeBackend({
        'GET /api/dormitories': {
          'dormitories': [dormJson(name: 'Sunrise Dorm')],
        },
      }),
    );

    expect(find.text('Search dorms'), findsOneWidget);
    expect(find.text('Sunrise Dorm'), findsOneWidget);
    expect(find.text('1 dorms found'), findsOneWidget);
  });

  testWidgets('2. No results shows a Clear filters button', (tester) async {
    await openSearch(
      tester,
      fakeBackend({
        'GET /api/dormitories': {'dormitories': []},
      }),
    );

    expect(find.text('No dorms found'), findsOneWidget);
    expect(find.text('Clear filters'), findsOneWidget);
  });

  testWidgets('3. Typing a name sends it to the backend', (tester) async {
    final requests = <http.Request>[];
    await openSearch(
      tester,
      fakeBackend({
        'GET /api/dormitories': {'dormitories': []},
      }, requests: requests),
    );

    await tester.enterText(find.byType(TextField).first, 'Sunrise');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(lastSearch(requests)['q'], 'Sunrise');
  });

  testWidgets('4. Choosing a zone searches only that zone', (tester) async {
    final requests = <http.Request>[];
    await openSearch(
      tester,
      fakeBackend({
        'GET /api/dormitories': {'dormitories': []},
      }, requests: requests),
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Back gate'));
    await tester.pumpAndSettle();

    expect(lastSearch(requests)['zone'], 'หลังมอ');
  });
}
