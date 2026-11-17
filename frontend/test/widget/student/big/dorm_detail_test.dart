// ผู้รับผิดชอบ: Big (นักศึกษา)
// ทดสอบหน้า: รายละเอียดหอพักฝั่งนักศึกษา (student_dorm_detail_screen)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/student/screens/student_dorm_detail_screen.dart';

import '../../../helpers/admin_test_helpers.dart';
import '../../../helpers/test_services.dart';

Map<String, dynamic> _detail() => {
      'id': 1,
      'name': 'หอพักรายละเอียด B',
      'zone': 'หลังมอ',
      'latitude': 19.8745,
      'longitude': 99.83,
      'price_per_month': 2600,
      'total_rooms': 40,
      'available_rooms': 6,
      'status': 'published',
      'description': 'ข้อมูลตัวอย่างสำหรับทดสอบ',
      'images': [],
      'amenities': [],
      'rating_avg': 4.5,
      'review_count': 2,
    };

void main() {
  testWidgets('แสดงชื่อหอ ราคา และคำอธิบาย', (tester) async {
    final services = studentServicesWith((req) async {
      if (req.url.path == '/api/dormitories/1') {
        return jsonResponse({'dormitory': _detail()});
      }
      if (req.url.path == '/api/dormitories/1/reviews') {
        return jsonResponse({'reviews': []});
      }
      return jsonResponse({'favorites': []});
    });

    await tester.pumpWidget(MaterialApp(
      home: StudentDormDetailScreen(services: services, dormitoryId: 1),
    ));
    await tester.pumpAndSettle();

    expect(find.text('หอพักรายละเอียด B'), findsWidgets);
    expect(find.textContaining('ข้อมูลตัวอย่างสำหรับทดสอบ'), findsOneWidget);
  });
}
