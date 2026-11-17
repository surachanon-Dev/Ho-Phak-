// ผู้รับผิดชอบ: Big (นักศึกษา)
// ทดสอบหน้า: หน้าหลักนักศึกษา (student_home_screen)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/student/screens/student_home_screen.dart';
import 'package:hopak_frontend/shared/models/user.dart';

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
  final student = CurrentUser(id: 9, role: 'student', status: 'active', isVerified: false, username: 'ทดสอบ');

  testWidgets('หน้าหลักแสดงชื่อผู้ใช้และรายการหอพักที่เผยแพร่', (tester) async {
    final services = studentServicesWith((req) async {
      if (req.url.path == '/api/dormitories') {
        return jsonResponse({'dormitories': [_dorm(1, 'หอพักทดสอบ A')]});
      }
      return jsonResponse({'error': 'not mocked'}, 404);
    });

    await tester.pumpWidget(MaterialApp(
      home: StudentHomeScreen(services: services, user: student),
    ));
    await tester.pumpAndSettle();

    expect(find.text('สวัสดี, ทดสอบ'), findsOneWidget);
    expect(find.text('หอพักทดสอบ A'), findsOneWidget);
  });

  testWidgets('ไม่มีหอพักที่เผยแพร่ แสดงข้อความว่าง', (tester) async {
    final services = studentServicesWith((req) async => jsonResponse({'dormitories': []}));

    await tester.pumpWidget(MaterialApp(
      home: StudentHomeScreen(services: services, user: student),
    ));
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีหอพักที่เผยแพร่'), findsOneWidget);
  });

  testWidgets('โหลดไม่สำเร็จแสดงข้อความและปุ่มลองอีกครั้ง', (tester) async {
    final services = studentServicesWith((req) async => jsonResponse({'message': 'down'}, 500));

    await tester.pumpWidget(MaterialApp(
      home: StudentHomeScreen(services: services, user: student),
    ));
    await tester.pumpAndSettle();

    expect(find.text('โหลดหอพักไม่ได้'), findsOneWidget);
    expect(find.text('ลองอีกครั้ง'), findsOneWidget);
  });
}
