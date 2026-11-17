// ผู้รับผิดชอบ: Big (นักศึกษา)
// ทดสอบหน้า: รายการโปรด (favorites_screen)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/student/screens/favorites_screen.dart';

import '../../../helpers/admin_test_helpers.dart';
import '../../../helpers/test_services.dart';

void main() {
  testWidgets('แสดงหอพักที่บันทึกเป็นรายการโปรด', (tester) async {
    final services = studentServicesWith((req) async => jsonResponse({
          'favorites': [
            {
              'id': 1,
              'name': 'หอพักโปรด C',
              'zone': 'หน้ามอ',
              'price_per_month': 3200,
              'status': 'published',
              'saved_at': '2026-11-10T10:00:00.000Z',
            },
          ],
        }));

    await tester.pumpWidget(MaterialApp(
      home: FavoritesScreen(services: services, myUserId: 9),
    ));
    await tester.pumpAndSettle();

    expect(find.text('รายการโปรด'), findsOneWidget);
    expect(find.text('หอพักโปรด C'), findsOneWidget);
  });

  testWidgets('ยังไม่มีรายการโปรดแสดงข้อความและปุ่มไปค้นหา', (tester) async {
    final services = studentServicesWith((req) async => jsonResponse({'favorites': []}));

    await tester.pumpWidget(MaterialApp(
      home: FavoritesScreen(services: services, myUserId: 9),
    ));
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีหอพักในรายการโปรด'), findsOneWidget);
    expect(find.text('ไปค้นหาหอพัก'), findsOneWidget);
  });
}
