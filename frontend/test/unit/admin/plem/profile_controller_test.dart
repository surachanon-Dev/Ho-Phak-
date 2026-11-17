// ผู้รับผิดชอบ: Plem (แอดมิน)
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

  group('AdminProfileController', () {
    test('load ดึงบัญชีที่ login อยู่ และ logout ลบ token', () async {
      final tokens = TokenStore();
      await tokens.save('token-abc');
      final api = ApiClient(
        tokenProvider: () => tokens.token,
        client: MockClient((req) async => _json({
          'user': {'id': 7, 'username': 'Test Admin', 'role': 'admin', 'status': 'active', 'is_verified': 1},
        })),
      );
      final c = AdminProfileController(AuthService(api, tokens));

      expect(await c.load(), isTrue);
      expect(c.user?.role, 'admin');
      expect(c.loading, isFalse);

      await c.logout();
      expect(tokens.token, isNull);
    });

    test('load ล้มเหลวเก็บ error', () async {
      final tokens = TokenStore();
      final api = ApiClient(
        tokenProvider: () => tokens.token,
        client: MockClient((req) async => _json({'message': 'ไม่พบผู้ใช้งาน'}, 401)),
      );
      final c = AdminProfileController(AuthService(api, tokens));
      expect(await c.load(), isFalse);
      expect(c.error, isA<ApiException>());
    });
  });

  test('ไอคอนและการใช้ Material ไม่ทำให้ไฟล์เทสต์ล้มเหลว (sanity)', () {
    expect(Icons.refresh, isNotNull);
  });

}
