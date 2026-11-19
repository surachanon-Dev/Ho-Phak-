// ผู้รับผิดชอบ: Plem (แอดมิน)
// ไฟล์นี้เป็นเทสต์ widget ของหน้าที่ระบุในชื่อไฟล์
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/admin/amenities/admin_amenities_tab.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/admin_test_helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Amenities ไม่ overflow บนจอมือถือ', (tester) async {
    await expectPhoneLayout(
      tester,
      AdminAmenitiesTab(services: sampleDataServices()),
    );
  });

  testWidgets('Amenities rejects a duplicate name in the add dialog', (
    tester,
  ) async {
    final writes = <http.Request>[];
    await _openAmenities(tester, (request) async {
      if (request.method != 'GET') writes.add(request);
      return jsonResponse({
        'amenities': [_wifi],
      });
    });

    await _saveNewAmenity(tester, '  wi-fi  ');

    expect(find.text('This amenity name already exists.'), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
    expect(writes, isEmpty);
  });

  testWidgets('Amenities saves a new item and displays it after reloading', (
    tester,
  ) async {
    final writes = <http.Request>[];
    await _openAmenities(tester, (request) async {
      if (request.method == 'POST') {
        writes.add(request);
        return jsonResponse({'id': 11}, 201);
      }
      return jsonResponse({
        'amenities': [
          _wifi,
          if (writes.isNotEmpty) {'id': 11, 'name': 'Study room'},
        ],
      });
    });

    expect(find.text('Study room'), findsNothing);
    await _saveNewAmenity(tester, '  Study room  ');

    final request = writes.single;
    expect(request.url.path, '/api/admin/amenities');
    expect(jsonDecode(request.body), {'name': 'Study room'});
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Study room'), findsOneWidget);
  });

  testWidgets('Amenities removes the selected item after confirming Delete', (
    tester,
  ) async {
    final writes = <http.Request>[];
    await _openAmenities(tester, (request) async {
      if (request.method == 'DELETE') {
        writes.add(request);
        return jsonResponse({});
      }
      return jsonResponse({
        'amenities': writes.isEmpty ? [_wifi] : [],
      });
    });

    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete amenity?'), findsOneWidget);
    expect(writes, isEmpty);

    await tester.tap(
      find.descendant(of: find.byType(Dialog), matching: find.text('Delete')),
    );
    await tester.pumpAndSettle();

    expect(writes.single.url.path, '/api/admin/amenities/5');
    expect(find.text('Wi-Fi'), findsNothing);
    expect(find.text('No amenities'), findsOneWidget);
  });
}

const _wifi = {'id': 5, 'name': 'Wi-Fi'};

Future<void> _openAmenities(WidgetTester tester, RequestHandler handler) async {
  setScreenSize(tester, const Size(390, 844));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: AdminAmenitiesTab(services: servicesWith(handler))),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _saveNewAmenity(WidgetTester tester, String name) async {
  await tester.tap(find.widgetWithText(ElevatedButton, '+ Add amenity'));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.descendant(of: find.byType(Dialog), matching: find.byType(TextField)),
    name,
  );
  await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
  await tester.pumpAndSettle();
}
