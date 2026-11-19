// ผู้รับผิดชอบ: Big (นักศึกษา)
// widget test: หน้ารายการโปรด
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/modules/student/favorites/view/favorites_screen.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/fake_backend.dart';
import '../../../helpers/student_data.dart';

Future<void> openFavorites(WidgetTester tester, AppServices services) async {
  useDesktopScreen(tester);
  await tester.pumpWidget(
    MaterialApp(home: FavoritesScreen(services: services, myUserId: 9)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('1. Saved dorms are listed', (tester) async {
    await openFavorites(
      tester,
      fakeBackend({
        'GET /api/favorites': {
          'favorites': [favoriteJson(name: 'Sunrise Dorm')],
        },
      }),
    );

    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Sunrise Dorm'), findsOneWidget);
  });

  testWidgets('2. A dorm that is no longer published is marked Unavailable', (
    tester,
  ) async {
    await openFavorites(
      tester,
      fakeBackend({
        'GET /api/favorites': {
          'favorites': [favoriteJson(name: 'Closed Dorm', status: 'suspended')],
        },
      }),
    );

    expect(find.text('Closed Dorm'), findsOneWidget);
    expect(find.text('Unavailable'), findsOneWidget);
  });

  testWidgets('3. Remove takes the dorm off the list', (tester) async {
    final requests = <http.Request>[];
    await openFavorites(
      tester,
      fakeBackend({
        'GET /api/favorites': {
          'favorites': [favoriteJson(id: 1, name: 'Sunrise Dorm')],
        },
        'DELETE /api/favorites/1': {'ok': true},
      }, requests: requests),
    );

    await tester.tap(find.byTooltip('Remove'));
    await tester.pumpAndSettle();

    expect(
      requests.where((r) => r.method == 'DELETE').single.url.path,
      '/api/favorites/1',
    );
    expect(find.text('Removed from favorites'), findsOneWidget);
    expect(find.text('Sunrise Dorm'), findsNothing);
  });

  testWidgets('4. No favorites shows a Find dorms button', (tester) async {
    await openFavorites(
      tester,
      fakeBackend({
        'GET /api/favorites': {'favorites': []},
      }),
    );

    expect(find.text('No favorite dorms yet'), findsOneWidget);
    expect(find.text('Find dorms'), findsOneWidget);
  });
}
