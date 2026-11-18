// ผู้รับผิดชอบ: Bank (แอดมิน)
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

  group('AdminDormsController', () {
    http.Response dormsRoute(http.Request req) {
      switch (req.url.path) {
        case '/api/admin/queue':
          return _json({
            'new_dormitories': [
              {'id': 10, 'name': 'หอใหม่', 'zone': 'หน้ามอ', 'owner_id': 2, 'owner_username': 'bank'},
            ],
            'revisions': [
              {'id': 5, 'dormitory_id': 11, 'dormitory_name': 'หอเก่า', 'payload': '{}'},
            ],
            'verifications': [],
          });
        case '/api/admin/dormitories':
          return _json({
            'dormitories': [
              {'id': 11, 'name': 'หอเก่า', 'status': req.url.queryParameters['status'] ?? 'published'},
            ],
          });
        default:
          return _json({'message': 'ok'});
      }
    }

    test('loadQueue นับหอรอตรวจทั้งหอใหม่และฉบับแก้ไข', () async {
      final c = AdminDormsController(_admin(dormsRoute, []));

      expect(await c.loadQueue(), isTrue);

      expect(c.newDormitories.length, 1);
      expect(c.revisions.length, 1);
      expect(c.awaitingCount, 2);
    });

    test('loadAll ส่งตัวกรองสถานะและจำค่าไว้', () async {
      final log = <http.Request>[];
      final c = AdminDormsController(_admin(dormsRoute, log));

      expect(await c.loadAll(status: 'suspended'), isTrue);

      expect(log.single.url.queryParameters['status'], 'suspended');
      expect(c.statusFilter, 'suspended');
      expect(c.allDormitories.single['status'], 'suspended');
    });

    test('approve/suspend/restore/reject เรียกเส้นทางถูกต้อง', () async {
      final log = <http.Request>[];
      final c = AdminDormsController(_admin(dormsRoute, log));

      expect(await c.approve(10), isTrue);
      expect(await c.suspend(11, 'ละเมิดกติกา'), isTrue);
      expect(await c.restore(11), isTrue);
      expect(await c.reject(10, 'ภาพไม่ชัด'), isTrue);

      final posts = log.where((r) => r.method == 'POST').map((r) => r.url.path).toList();
      expect(posts, [
        '/api/admin/dormitories/10/approve',
        '/api/admin/dormitories/11/suspend',
        '/api/admin/dormitories/11/restore',
        '/api/admin/dormitories/10/reject',
      ]);
      expect(jsonDecode(log.firstWhere((r) => r.url.path.endsWith('/suspend')).body),
          {'reason': 'ละเมิดกติกา'});
    });

    test('suspend และ reject ที่ไม่มีเหตุผลไม่ยิง request', () async {
      final log = <http.Request>[];
      final c = AdminDormsController(_admin(dormsRoute, log));

      expect(await c.suspend(11, ' '), isFalse);
      expect(await c.reject(10, ''), isFalse);
      expect(log, isEmpty);
    });

    test('approve ที่ล้มเหลวคืน false และเก็บ error', () async {
      final c = AdminDormsController(_admin((req) => _json({'message': 'x'}, 409), []));
      expect(await c.approve(10), isFalse);
      expect(c.error, isA<ApiException>());
      expect(c.busy, isFalse);
    });

    test('validateReason จำกัดความยาว 300 ตัวอักษร', () {
      expect(AdminDormsController.validateReason('ก' * 300, 'เหตุผล'), isNull);
      expect(AdminDormsController.validateReason('ก' * 301, 'เหตุผล'), isNotNull);
    });
  });

}
