// ผู้รับผิดชอบ: Karn (นักศึกษา)
// ทดสอบหน้า: รายการแชท และการแจ้งเตือน (chat_list_screen, notifications_screen)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/chat/screens/chat_list_screen.dart';
import 'package:hopak_frontend/features/notifications/screens/notifications_screen.dart';

import '../../../helpers/admin_test_helpers.dart';
import '../../../helpers/test_services.dart';

void main() {
  testWidgets('รายการแชทแสดงชื่อหอที่คุยอยู่', (tester) async {
    final services = studentServicesWith((req) async => jsonResponse({
          'conversations': [
            {
              'id': 1,
              'tenant_id': 9,
              'dormitory_name': 'หอพักแชท D',
              'dormitory_status': 'published',
              'unread_count': 0,
              'last_message': 'สวัสดีครับ',
              'last_sent_at': '2026-11-10T10:00:00.000Z',
            },
          ],
        }));

    await tester.pumpWidget(MaterialApp(
      home: ChatListScreen(services: services, myUserId: 9),
    ));
    await tester.pumpAndSettle();

    expect(find.text('หอพักแชท D'), findsWidgets);
  });

  testWidgets('การแจ้งเตือนแสดงหัวข้อของแต่ละรายการ', (tester) async {
    final services = studentServicesWith((req) async => jsonResponse({
          'notifications': [
            {
              'id': 1,
              'type': 'review',
              'title': 'มีรีวิวใหม่',
              'body': 'หอพักของคุณได้รับรีวิวใหม่',
              'created_at': '2026-11-10T10:00:00.000Z',
              'read_at': null,
            },
          ],
        }));

    await tester.pumpWidget(MaterialApp(
      home: NotificationsScreen(services: services),
    ));
    await tester.pumpAndSettle();

    expect(find.text('มีรีวิวใหม่'), findsOneWidget);
  });
}
