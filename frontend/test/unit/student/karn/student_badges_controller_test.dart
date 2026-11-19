// ผู้รับผิดชอบ: Karn (นักศึกษา)
// ไฟล์นี้เป็นเทสต์ unit ของจำนวนที่ยังไม่อ่าน (StudentBadgesController) และการสมัครเป็นเจ้าของหอ
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/student/controllers/student_badges_controller.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/admin_test_helpers.dart';
import '../../../helpers/test_services.dart';

void main() {
  group('StudentBadgesController', () {
    test('นับข้อความและการแจ้งเตือนที่ยังไม่อ่าน', () async {
      final services = studentServicesWith((req) async {
        if (req.url.path == '/api/conversations') {
          return jsonResponse({
            'conversations': [
              {'id': 1, 'tenant_id': 9, 'dormitory_name': 'A', 'dormitory_status': 'published', 'unread_count': 2},
              {'id': 2, 'tenant_id': 9, 'dormitory_name': 'B', 'dormitory_status': 'published', 'unread_count': 3},
            ],
          });
        }
        return jsonResponse({
          'notifications': [
            {'id': 1, 'type': 'x', 'title': 'a', 'created_at': '2026-11-10', 'read_at': null},
            {'id': 2, 'type': 'x', 'title': 'b', 'created_at': '2026-11-10', 'read_at': '2026-11-11'},
          ],
        });
      });
      final c = StudentBadgesController(
        chats: services.chats,
        notifications: services.notifications,
      );

      await c.refresh();
      expect(c.messages, 5);
      expect(c.notifications, 1);
    });

    test('โหลดไม่สำเร็จคงค่าเดิมไว้', () async {
      final services = studentServicesWith(
        (req) async => jsonResponse({'message': 'down'}, 500),
      );
      final c = StudentBadgesController(
        chats: services.chats,
        notifications: services.notifications,
      );

      await c.refresh();
      expect(c.messages, 0);
      expect(c.notifications, 0);
    });
  });

  test('becomeOwner เรียก POST /api/me/become-owner แล้วโหลดผู้ใช้ใหม่', () async {
    final calls = <String>[];
    final services = studentServicesWith((http.Request req) async {
      calls.add('${req.method} ${req.url.path}');
      if (req.url.path == '/api/me') {
        return jsonResponse({
          'user': {'id': 9, 'username': 'big', 'role': 'owner', 'status': 'active', 'is_verified': 0},
        });
      }
      return jsonResponse({'message': 'ok'});
    });

    final user = await services.auth.becomeOwner();
    expect(calls, ['POST /api/me/become-owner', 'GET /api/me']);
    expect(user.isOwner, isTrue);
    expect(user.isVerified, isFalse);
  });
}
