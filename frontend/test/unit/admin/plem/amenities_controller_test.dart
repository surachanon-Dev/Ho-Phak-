// ผู้รับผิดชอบ: Plem (แอดมิน)
// เทสต์ unit ของ controller ที่ระบุในชื่อ group
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/admin/amenities/amenities_controller.dart';
import 'package:hopak_frontend/features/admin/dashboard/dashboard_controller.dart';
import 'package:hopak_frontend/features/admin/dorms/dorms_controller.dart';
import 'package:hopak_frontend/features/admin/owner_requests/owner_requests_controller.dart';
import 'package:hopak_frontend/features/admin/profile/profile_controller.dart';
import 'package:hopak_frontend/features/admin/users/users_controller.dart';
import 'package:hopak_frontend/features/admin/services/admin_service.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:hopak_frontend/features/auth/services/auth_service.dart';
import 'package:hopak_frontend/core/network/token_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

/// AdminService บน ApiClient ที่ใช้ MockClient; บันทึก request ทั้งหมดไว้ใน [log]
AdminService _admin(
  http.Response Function(http.Request req) handler,
  List<http.Request> log,
) {
  final api = ApiClient(
    tokenProvider: () => 'admin-token',
    client: MockClient((req) async {
      log.add(req);
      return handler(req);
    }),
  );
  return AdminService(api);
}

Map<String, dynamic> _verification(int id, {String status = 'pending', String? reason}) => {
  'id': id,
  'owner_id': 20 + id,
  'document_url': 'private_uploads/doc-$id.pdf',
  'status': status,
  'submitted_at': '2026-11-10T10:00:00.000Z',
  'reviewed_at': null,
  'rejection_reason': reason,
  'owner_username': 'owner$id',
  'first_name': 'สมชาย',
  'surname': 'ใจดี $id',
  'owner_phone': '08100000$id',
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('AdminAmenitiesController', () {
    http.Response amenitiesRoute(http.Request req) {
      if (req.method == 'GET') {
        return _json({
          'amenities': [
            {'id': 1, 'name': 'Wi-Fi'},
            {'id': 2, 'name': 'CCTV'},
          ],
        });
      }
      return _json({'message': 'ok', 'id': 9});
    }

    test('load แปลงแถวเป็น AdminAmenity', () async {
      final c = AdminAmenitiesController(_admin(amenitiesRoute, []));

      expect(await c.load(), isTrue);

      expect(c.items.map((a) => a.id), [1, 2]);
      expect(c.items.first.name, 'Wi-Fi');
    });

    test('validateName: ว่าง, ยาวเกิน 100, ซ้ำโดยไม่สนตัวพิมพ์, และยอมรับชื่อเดิมของตัวเอง', () async {
      final c = AdminAmenitiesController(_admin(amenitiesRoute, []));
      await c.load();

      expect(c.validateName('  '), isNotNull);
      expect(c.validateName('ก' * 101), isNotNull);
      expect(c.validateName('wi-fi'), 'This amenity name already exists.');
      expect(c.validateName('Wi-Fi', exceptId: 1), isNull);
      expect(c.validateName('Pool'), isNull);
    });

    test('add ส่งชื่อที่ตัดช่องว่างแล้วและโหลดใหม่', () async {
      final log = <http.Request>[];
      final c = AdminAmenitiesController(_admin(amenitiesRoute, log));

      expect(await c.add('  สระว่ายน้ำ  '), isTrue);

      final post = log.firstWhere((r) => r.method == 'POST');
      expect(post.url.path, '/api/admin/amenities');
      expect(jsonDecode(post.body), {'name': 'สระว่ายน้ำ'});
    });

    test('add ชื่อซ้ำไม่ยิง request', () async {
      final log = <http.Request>[];
      final c = AdminAmenitiesController(_admin(amenitiesRoute, log));
      await c.load();
      log.clear();

      expect(await c.add('CCTV'), isFalse);
      expect(log, isEmpty);
      expect(c.error, isA<ApiException>());
    });

    test('rename ส่ง PUT ไปที่ id ที่ถูกต้อง', () async {
      final log = <http.Request>[];
      final c = AdminAmenitiesController(_admin(amenitiesRoute, log));
      await c.load();

      expect(await c.rename(2, 'กล้องวงจรปิด'), isTrue);

      final put = log.firstWhere((r) => r.method == 'PUT');
      expect(put.url.path, '/api/admin/amenities/2');
      expect(jsonDecode(put.body), {'name': 'กล้องวงจรปิด'});
    });

    test('delete ส่ง DELETE และโหลดใหม่', () async {
      final log = <http.Request>[];
      final c = AdminAmenitiesController(_admin(amenitiesRoute, log));

      expect(await c.delete(1), isTrue);

      expect(log.first.method, 'DELETE');
      expect(log.first.url.path, '/api/admin/amenities/1');
    });

    test('ลบไม่สำเร็จเก็บ error', () async {
      final c = AdminAmenitiesController(_admin((req) => _json({'message': 'x'}, 404), []));
      expect(await c.delete(99), isFalse);
      expect(c.error, isA<ApiException>());
    });
  });

}
