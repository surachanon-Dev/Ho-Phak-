// ผู้รับผิดชอบ: Bank (แอดมิน)
// เทสต์ unit ของ controller ที่ระบุในชื่อ group
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/admin/amenities/admin_amenities_controller.dart';
import 'package:hopak_frontend/features/admin/dashboard/admin_dashboard_controller.dart';
import 'package:hopak_frontend/features/admin/dorms/admin_dorms_controller.dart';
import 'package:hopak_frontend/features/admin/owner_requests/admin_owner_requests_controller.dart';
import 'package:hopak_frontend/features/admin/profile/admin_profile_controller.dart';
import 'package:hopak_frontend/features/admin/users/admin_users_controller.dart';
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

  group('AdminOwnerRequestsController', () {
    http.Response verificationsRoute(http.Request req) {
      final status = req.url.queryParameters['status'];
      return _json({
        'verifications': switch (status) {
          'pending' => [_verification(1), _verification(2)],
          'approved' => [_verification(3, status: 'approved')],
          'rejected' => [_verification(4, status: 'rejected', reason: 'เอกสารไม่ชัด')],
          _ => <Map<String, dynamic>>[],
        },
      });
    }

    test('load แยกสามแท็บและนับรายการรอตรวจ', () async {
      final log = <http.Request>[];
      final c = AdminOwnerRequestsController(_admin((req) {
        if (req.url.path == '/api/admin/verifications') return verificationsRoute(req);
        return _json({});
      }, log));

      expect(await c.load(), isTrue);

      expect(c.pending.length, 2);
      expect(c.approved.length, 1);
      expect(c.rejected.single['rejection_reason'], 'เอกสารไม่ชัด');
      expect(c.pendingCount, 2);
      expect(c.loading, isFalse);
      expect(log.map((r) => r.url.queryParameters['status']).toSet(), {'pending', 'approved', 'rejected'});
    });

    test('approve ส่ง POST แล้วโหลดรายการใหม่', () async {
      final log = <http.Request>[];
      final c = AdminOwnerRequestsController(_admin((req) {
        if (req.url.path == '/api/admin/verifications') return verificationsRoute(req);
        return _json({'message': 'อนุมัติการยืนยันตัวตนแล้ว'});
      }, log));

      expect(await c.approve(1), isTrue);

      final post = log.firstWhere((r) => r.method == 'POST');
      expect(post.url.path, '/api/admin/verifications/1/approve');
      expect(c.busy, isFalse);
      expect(log.where((r) => r.url.path == '/api/admin/verifications').length, 3,
          reason: 'โหลดใหม่หลังอนุมัติ');
    });

    test('reject ต้องมีเหตุผลและไม่เกิน 300 ตัวอักษร โดยไม่ยิง request', () async {
      final log = <http.Request>[];
      final c = AdminOwnerRequestsController(_admin((req) => _json({}), log));

      expect(await c.reject(1, '   '), isFalse);
      expect(await c.reject(1, 'ก' * 301), isFalse);
      expect(log, isEmpty);
      expect(c.error, isA<ApiException>());
    });

    test('reject ส่งเหตุผลที่ตัดช่องว่างแล้ว', () async {
      final log = <http.Request>[];
      final c = AdminOwnerRequestsController(_admin((req) => _json({}), log));

      expect(await c.reject(2, '  เอกสารไม่ชัด  '), isTrue);

      final post = log.firstWhere((r) => r.method == 'POST');
      expect(post.url.path, '/api/admin/verifications/2/reject');
      expect(jsonDecode(post.body), {'reason': 'เอกสารไม่ชัด'});
    });

    test('approve ที่ server ปฏิเสธเก็บ error และไม่โหลดใหม่', () async {
      final log = <http.Request>[];
      final c = AdminOwnerRequestsController(_admin((req) {
        if (req.method == 'POST') return _json({'message': 'ไม่พบคำขอ'}, 404);
        return _json({'verifications': []});
      }, log));

      expect(await c.approve(9), isFalse);
      expect(c.error, isA<ApiException>());
      expect(log.where((r) => r.method == 'GET'), isEmpty);
    });

    test('validateRejectReason และ displayName', () {
      expect(AdminOwnerRequestsController.validateRejectReason(''), isNotNull);
      expect(AdminOwnerRequestsController.validateRejectReason('ok'), isNull);
      expect(
        AdminOwnerRequestsController.displayName({'first_name': 'สมชาย', 'surname': 'ใจดี'}),
        'สมชาย ใจดี',
      );
      expect(
        AdminOwnerRequestsController.displayName({'owner_username': 'bank', 'owner_id': 1}),
        'bank',
      );
      expect(AdminOwnerRequestsController.displayName({'owner_id': 7}), 'Owner #7');
    });
  });

}
