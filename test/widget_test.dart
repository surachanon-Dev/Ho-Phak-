import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ho_phak_1/owner/controller/owner_controller.dart';
import 'package:ho_phak_1/owner/owner_app.dart';

Future<void> _login(WidgetTester tester) async {
  await tester.pumpWidget(const OwnerApp());
  await tester.enterText(find.byType(TextField).at(0), 'owner_test1');
  await tester.enterText(find.byType(TextField).at(1), 'password123');
  await tester.tap(find.widgetWithText(FilledButton, 'เข้าสู่ระบบ'));
  await tester.pumpAndSettle();
}

void main() {
  // ไม่โหลดฟอนต์จากอินเทอร์เน็ตตอนทดสอบ
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() async => OwnerController.logout());

  testWidgets('เปิดแอปแล้วเจอหน้าเข้าสู่ระบบ', (tester) async {
    await tester.pumpWidget(const OwnerApp());
    expect(find.text('สมัครสมาชิก'), findsOneWidget);
  });

  testWidgets('รหัสผ่านผิดแล้วแจ้งเตือน ไม่เข้าหน้าหลัก', (tester) async {
    await tester.pumpWidget(const OwnerApp());
    await tester.enterText(find.byType(TextField).at(0), 'owner_test1');
    await tester.enterText(find.byType(TextField).at(1), 'wrong-password');
    await tester.tap(find.widgetWithText(FilledButton, 'เข้าสู่ระบบ'));
    await tester.pumpAndSettle();
    expect(find.text('รหัสผ่านไม่ถูกต้อง'), findsOneWidget);
    expect(find.text('หอพักของฉัน'), findsNothing);
  });

  testWidgets('ล็อกอินแล้วเห็นหอตัวอย่าง', (tester) async {
    await _login(tester);
    expect(find.text('หอพักของฉัน'), findsOneWidget);
    expect(find.text('บ้านสวนลำดวน'), findsOneWidget);
    expect(find.text('หอพักนภา'), findsOneWidget);
  });

  testWidgets('ฟอร์มเพิ่มหอมีแผนที่จริง และบันทึกโดยไม่กรอกชื่อไม่ผ่าน', (tester) async {
    await _login(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'เพิ่มหอ'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.byType(FlutterMap), 400, scrollable: find.byType(Scrollable).first);
    expect(find.byType(FlutterMap), findsOneWidget);

    await tester.scrollUntilVisible(find.text('บันทึกและส่งตรวจ'), 400, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('บันทึกและส่งตรวจ'));
    await tester.pump();
    expect(find.text('กรอกชื่อหอพัก'), findsOneWidget);
  });
}
