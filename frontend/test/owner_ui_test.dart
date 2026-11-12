import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/models/dormitory.dart';
import 'package:hopak_frontend/screens/owner/dashboard_screen.dart' show formatBaht;
import 'package:hopak_frontend/ui/status_style.dart';

void main() {
  test('formatBaht ใส่จุลภาคคั่นหลักพัน', () {
    expect(formatBaht(950), '950');
    expect(formatBaht(3200), '3,200');
    expect(formatBaht(1000000), '1,000,000');
  });

  test('DormStatus.label เป็นภาษาอังกฤษทุกสถานะ', () {
    expect(DormStatus.label(DormStatus.pending), 'Pending review');
    expect(DormStatus.label(DormStatus.published), 'Published');
    expect(DormStatus.label(DormStatus.changesPending), 'Changes pending');
    expect(DormStatus.label(DormStatus.rejected), 'Rejected');
    expect(DormStatus.label(DormStatus.hidden), 'Hidden');
    expect(DormStatus.label(DormStatus.suspended), 'Suspended');
  });

  testWidgets('StatusChip แสดงข้อความสถานะ', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusChip(displayStatus: DormStatus.suspended),
        ),
      ),
    );
    expect(find.text('Suspended'), findsOneWidget);
  });
}
