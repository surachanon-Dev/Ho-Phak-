// ผู้รับผิดชอบ: Big (นักศึกษา)
// ทดสอบหน้า: ค้นหาหอพัก (search_screen)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/student/screens/search_screen.dart';

import '../../../helpers/admin_test_helpers.dart';
import '../../../helpers/test_services.dart';

Map<String, dynamic> _dorm(int id, String name) => {
      'id': id,
      'name': name,
      'zone': 'หน้ามอ',
      'latitude': 19.8795,
      'longitude': 99.8352,
      'price_per_month': 3000,
      'total_rooms': 10,
      'available_rooms': 2,
      'status': 'published',
    };

void main() {
  testWidgets('แสดงหอพักที่ค้นได้และหัวข้อหน้าค้นหา', (tester) async {
    final services = studentServicesWith((req) async => jsonResponse({'dormitories': [_dorm(1, 'หอพักค้นหา A')]}));

    await tester.pumpWidget(MaterialApp(home: SearchScreen(services: services)));
    await tester.pumpAndSettle();

    expect(find.text('Search dorms'), findsOneWidget);
    expect(find.text('หอพักค้นหา A'), findsOneWidget);
  });

  testWidgets('ไม่พบหอพักแสดงข้อความและปุ่มล้างตัวกรอง', (tester) async {
    final services = studentServicesWith((req) async => jsonResponse({'dormitories': []}));

    await tester.pumpWidget(MaterialApp(home: SearchScreen(services: services)));
    await tester.pumpAndSettle();

    expect(find.text('No dorms found'), findsOneWidget);
    expect(find.text('Clear filters'), findsOneWidget);
  });

  testWidgets('พิมพ์คำค้นแล้วส่งคำค้นไปที่ API', (tester) async {
    final queries = <String?>[];
    final services = studentServicesWith((req) async {
      queries.add(req.url.queryParameters['q']);
      return jsonResponse({'dormitories': []});
    });

    await tester.pumpWidget(MaterialApp(home: SearchScreen(services: services)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'กิตติยา');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(queries.any((q) => q == 'กิตติยา'), isTrue);
  });
}
