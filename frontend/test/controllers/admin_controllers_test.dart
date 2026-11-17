import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/admin/moderation/admin_amenities_controller.dart';
import 'package:hopak_frontend/features/admin/dashboard/admin_dashboard_controller.dart';
import 'package:hopak_frontend/features/admin/dorms/admin_dorms_controller.dart';
import 'package:hopak_frontend/features/admin/owner_requests/admin_owner_requests_controller.dart';
import 'package:hopak_frontend/features/admin/profile/admin_profile_controller.dart';
import 'package:hopak_frontend/features/admin/moderation/admin_users_controller.dart';
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

  group('AdminUsersController', () {
    test('load ส่งตัวกรอง role/status และเก็บรายการ', () async {
      final log = <http.Request>[];
      final c = AdminUsersController(_admin((req) => _json({
        'users': [
          {'id': 2, 'username': 'bank', 'role': 'owner', 'status': 'active', 'is_verified': 1},
        ],
      }), log));

      expect(await c.load(role: 'owner', status: 'active'), isTrue);

      expect(log.single.url.queryParameters, {'role': 'owner', 'status': 'active'});
      expect(c.users.single['username'], 'bank');
    });

    test('suspend ต้องมีเหตุผล และส่งเหตุผลที่ตัดช่องว่างแล้ว', () async {
      final log = <http.Request>[];
      final c = AdminUsersController(_admin((req) => _json({'users': []}), log));

      expect(await c.suspend(2, '   '), isFalse);
      expect(log, isEmpty);

      expect(await c.suspend(2, ' spam '), isTrue);
      final post = log.firstWhere((r) => r.method == 'POST');
      expect(post.url.path, '/api/admin/users/2/suspend');
      expect(jsonDecode(post.body), {'reason': 'spam'});
    });

    test('restore เรียก POST และโหลดรายการใหม่', () async {
      final log = <http.Request>[];
      final c = AdminUsersController(_admin((req) => _json({'users': []}), log));

      expect(await c.restore(2), isTrue);

      expect(log.first.url.path, '/api/admin/users/2/restore');
      expect(log.last.method, 'GET');
    });

    test('displayRole และ displayStatus แปลงค่าจาก API', () {
      expect(AdminUsersController.displayRole('owner'), 'Owner');
      expect(AdminUsersController.displayRole(null), '-');
      expect(AdminUsersController.displayStatus('suspended'), 'Suspended');
      expect(AdminUsersController.displayStatus('active'), 'Active');
    });
  });

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
