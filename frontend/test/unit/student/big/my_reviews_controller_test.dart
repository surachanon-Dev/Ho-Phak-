// ผู้รับผิดชอบ: Big (นักศึกษา)
// ไฟล์นี้เป็นเทสต์ unit ของรีวิวของฉัน (MyReviewsController), รูปปกในรายการ และชื่อโซนภาษาอังกฤษ
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/student/controllers/my_reviews_controller.dart';
import 'package:hopak_frontend/shared/models/dormitory.dart';
import 'package:hopak_frontend/shared/models/favorite.dart';

import '../../../helpers/admin_test_helpers.dart';
import '../../../helpers/test_services.dart';

Map<String, dynamic> _review(int id, {String status = 'pending'}) => {
  'id': id,
  'dormitory_id': 10 + id,
  'dormitory_name': 'Dorm $id',
  'rating': 4,
  'body': 'Nice',
  'status': status,
  'moderation_reason': status == 'hidden' ? 'Spam' : null,
  'created_at': '2026-11-10T10:00:00Z',
};

void main() {
  group('MyReviewsController', () {
    test('load แสดงรีวิวทุกสถานะ พร้อมเหตุผลเมื่อถูกซ่อน', () async {
      final services = studentServicesWith((req) async {
        expect(req.url.path, '/api/reviews/me');
        return jsonResponse({
          'reviews': [_review(1), _review(2, status: 'hidden')],
        });
      });
      final c = MyReviewsController(services.publicDorms);

      expect(await c.load(), isTrue);
      expect(c.items.length, 2);
      expect(c.items[1].isHidden, isTrue);
      expect(c.items[1].moderationReason, 'Spam');
    });

    test('update ส่ง PUT แล้วโหลดใหม่ ส่วนคะแนนนอกช่วงไม่ยิง request', () async {
      final calls = <String>[];
      Map<String, dynamic>? sent;
      final services = studentServicesWith((req) async {
        calls.add('${req.method} ${req.url.path}');
        if (req.method == 'PUT') sent = jsonDecode(req.body);
        return jsonResponse({'reviews': [_review(1)]});
      });
      final c = MyReviewsController(services.publicDorms);

      expect(await c.update(1, rating: 0), isFalse);
      expect(calls, isEmpty);

      expect(await c.update(1, rating: 5, body: '  Great  '), isTrue);
      expect(calls, ['PUT /api/reviews/1', 'GET /api/reviews/me']);
      expect(sent, {'rating': 5, 'body': 'Great'});
    });

    test('remove ลบออกจากรายการทันทีเมื่อสำเร็จ', () async {
      final services = studentServicesWith((req) async {
        if (req.method == 'DELETE') return jsonResponse({'message': 'ok'});
        return jsonResponse({
          'reviews': [_review(1), _review(2)],
        });
      });
      final c = MyReviewsController(services.publicDorms);
      await c.load();

      expect(await c.remove(1), isTrue);
      expect(c.items.map((r) => r.id), [2]);
    });
  });

  group('cover image และชื่อโซน', () {
    test('Dormitory ใช้ cover_image เมื่อไม่มี images', () {
      final d = Dormitory.fromJson({
        'id': 1,
        'name': 'A',
        'zone': 'หน้ามอ',
        'latitude': 19.88,
        'longitude': 99.83,
        'price_per_month': 3000,
        'cover_image': 'uploads/a.jpg',
      });
      expect(d.coverUrl, endsWith('/uploads/a.jpg'));
    });

    test('Favorite ไม่มีรูปคืน null', () {
      final f = Favorite.fromJson({
        'id': 1,
        'name': 'A',
        'zone': 'หลังมอ',
        'price_per_month': 3000,
        'status': 'published',
      });
      expect(f.coverUrl, isNull);
    });

    test('zoneLabel แปลงชื่อโซนเป็นอังกฤษ ค่าที่ไม่รู้จักคืนค่าเดิม', () {
      expect(zoneLabel('หน้ามอ'), 'Front gate');
      expect(zoneLabel('หลังมอ'), 'Back gate');
      expect(zoneLabel('คชพลแลนด์'), 'Kotchapol Land');
      expect(zoneLabel('อื่น ๆ'), 'อื่น ๆ');
    });
  });
}
