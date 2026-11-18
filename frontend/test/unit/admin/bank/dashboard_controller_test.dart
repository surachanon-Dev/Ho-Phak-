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

  group('AdminDashboardController', () {
    test('นับตัวเลขจากคิว รีวิวรอตรวจ และหอที่ถูกระงับ', () async {
      final c = AdminDashboardController(_admin((req) {
        switch (req.url.path) {
          case '/api/admin/queue':
            return _json({
              'new_dormitories': [{'id': 1}, {'id': 2}],
              'revisions': [{'id': 3}],
              'verifications': [{'id': 4}],
            });
          case '/api/admin/reviews':
            return _json({'reviews': [{'id': 7}]});
          case '/api/admin/dormitories':
            return _json({'dormitories': [{'id': 9}]});
          case '/api/admin/users':
            return _json({'users': [{'id': 21}, {'id': 22}]});
          default:
            return _json({});
        }
      }, []));

      expect(await c.load(), isTrue);

      expect(c.dormsAwaitingCount, 3);
      expect(c.ownerRequestsCount, 1);
      expect(c.reportedReviewsCount, 1);
      expect(c.suspendedDormsCount, 1);
      expect(c.suspendedAccountsCount, 2);
      expect(c.suspendedCount, 3);
      expect(c.totalWaiting, 4);
      expect(c.allCaughtUp, isFalse);
    });

    test('ไม่มีรายการค้างเลยถือว่า all caught up', () async {
      final c = AdminDashboardController(_admin((req) {
        if (req.url.path == '/api/admin/queue') {
          return _json({'new_dormitories': [], 'revisions': [], 'verifications': []});
        }
        return _json({'reviews': [], 'dormitories': []});
      }, []));

      await c.load();

      expect(c.allCaughtUp, isTrue);
      expect(c.totalWaiting, 0);
    });

    test('โหลดไม่สำเร็จเก็บ error และ loading เป็น false', () async {
      final c = AdminDashboardController(_admin((req) => _json({'message': 'x'}, 500), []));
      expect(await c.load(), isFalse);
      expect(c.error, isA<ApiException>());
      expect(c.loading, isFalse);
    });
  });

}
