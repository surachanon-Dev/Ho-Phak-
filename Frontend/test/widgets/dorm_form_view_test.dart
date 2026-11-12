// Widget Test: add / edit dorm form (lib/views/owner/dorm_form_view.dart)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hophak_frontend/mock/mock_db.dart';
import 'package:hophak_frontend/views/owner/dorm_form_view.dart';

import '../helpers/test_app.dart';

void main() {
  final db = MockDb.instance;
  const owner = 2; // Big – has published, rejected and suspended dorms in the mock data

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db.currentUserId = owner;
  });

  int dormIdWithStatus(String status) =>
      db.dormitories.firstWhere((d) => d['owner_id'] == owner && d['status'] == status)['id'] as int;

  Future<void> openForm(WidgetTester tester, {int? dormId}) async {
    useTallScreen(tester);
    await tester.pumpWidget(page(DormFormView(dormId: dormId)));
    await settle(tester);
  }

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('f_save')));
    await tester.tap(find.byKey(const Key('f_save')));
    await tester.pump();
  }

  testWidgets('WID-27 new form has the title "เพิ่มหอพัก" and the pending notice', (tester) async {
    await openForm(tester);
    expect(find.text('เพิ่มหอพัก'), findsOneWidget);
    expect(find.textContaining('รอตรวจสอบ'), findsWidgets);
    expect(find.text('บันทึกและส่งตรวจสอบ'), findsOneWidget);
  });

  testWidgets('WID-28 empty name and price show errors', (tester) async {
    await openForm(tester);
    await save(tester);
    expect(find.text('จำเป็นต้องกรอก'), findsOneWidget);
    expect(find.text('กรอกเป็นตัวเลข'), findsOneWidget);
  });

  testWidgets('WID-29 price 0 is rejected', (tester) async {
    await openForm(tester);
    await tester.enterText(find.byKey(const Key('f_name')), 'หอทดสอบ');
    await tester.enterText(find.byKey(const Key('f_price')), '0');
    await save(tester);
    expect(find.text('ต้องไม่น้อยกว่า 1'), findsOneWidget);
  });

  testWidgets('WID-30 price field only accepts digits', (tester) async {
    await openForm(tester);
    await tester.enterText(find.byKey(const Key('f_price')), 'abc35-00');
    await tester.pump();
    expect(textOf(tester, const Key('f_price')), '3500');
  });

  testWidgets('WID-31 zone dropdown has all 3 zones', (tester) async {
    await openForm(tester);
    await tester.tap(find.byType(DropdownButtonFormField<String>).first); // first dropdown = zone
    await tester.pumpAndSettle();
    for (final z in ['หน้ามอ', 'หลังมอ', 'คชพลแลนด์']) {
      expect(find.text(z), findsWidgets, reason: 'zone $z is missing');
    }
  });

  testWidgets('WID-32 wrong contact phone shows an error', (tester) async {
    await openForm(tester);
    await tester.enterText(find.widgetWithText(TextFormField, 'เบอร์ติดต่อ'), '12345');
    await save(tester);
    expect(find.text('เบอร์โทรไม่ถูกต้อง'), findsOneWidget);
  });

  testWidgets('WID-33 valid fields but no map pin → asks to pin the location', (tester) async {
    await openForm(tester);
    await tester.enterText(find.byKey(const Key('f_name')), 'หอทดสอบ');
    await tester.enterText(find.byKey(const Key('f_price')), '3500');
    await save(tester);
    await tester.pump();
    expect(find.text('กรุณาปักหมุดตำแหน่งหอพักบนแผนที่'), findsOneWidget);
  });

  testWidgets('WID-34 editing a rejected dorm shows the reason and "send for review" button', (tester) async {
    await openForm(tester, dormId: dormIdWithStatus('rejected'));
    expect(find.text('แก้ไขหอพัก'), findsOneWidget);
    expect(find.text('ไม่อนุมัติ'), findsWidgets);
    expect(find.text('บันทึกและส่งตรวจสอบ'), findsOneWidget);
  });

  testWidgets('WID-35 editing a published dorm shows "บันทึกการแก้ไข"', (tester) async {
    await openForm(tester, dormId: dormIdWithStatus('published'));
    expect(find.text('บันทึกการแก้ไข'), findsOneWidget);
    expect(textOf(tester, const Key('f_name')), isNotEmpty); // existing data is loaded into the form
  });

  testWidgets('WID-36 a suspended dorm is read-only (no save button)', (tester) async {
    await openForm(tester, dormId: dormIdWithStatus('suspended'));
    expect(find.text('ถูกระงับโดยผู้ดูแลระบบ'), findsOneWidget);
    expect(find.byKey(const Key('f_save')), findsNothing);
  });
}
