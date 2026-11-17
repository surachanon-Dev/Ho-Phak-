// ผู้รับผิดชอบ: Karn (นักศึกษา)
// ทดสอบหน้า: โปรไฟล์นักศึกษา (student_profile_screen)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/student/screens/student_profile_screen.dart';
import 'package:hopak_frontend/shared/models/user.dart';

import '../../../helpers/admin_test_helpers.dart';
import '../../../helpers/test_services.dart';

void main() {
  final student = CurrentUser(id: 9, role: 'student', status: 'active', isVerified: false, username: 'ทดสอบ');

  testWidgets('แสดงหัวข้อโปรไฟล์และบทบาทนักศึกษา', (tester) async {
    final services = studentServicesWith((req) async => jsonResponse({}));

    await tester.pumpWidget(MaterialApp(
      home: StudentProfileScreen(services: services, user: student),
    ));
    await tester.pumpAndSettle();

    expect(find.text('โปรไฟล์'), findsOneWidget);
    expect(find.text('นักศึกษา'), findsOneWidget);
  });

  testWidgets('กดติดต่อแอดมินแล้วแสดงกล่องข้อความ', (tester) async {
    final services = studentServicesWith((req) async => jsonResponse({}));

    await tester.pumpWidget(MaterialApp(
      home: StudentProfileScreen(services: services, user: student),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ติดต่อแอดมิน'));
    await tester.pumpAndSettle();

    expect(find.text('เบอร์และอีเมลแอดมินยังไม่ได้กำหนด'), findsOneWidget);
  });
}
