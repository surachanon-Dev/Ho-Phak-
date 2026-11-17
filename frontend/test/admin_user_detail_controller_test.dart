import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/controllers/admin_user_detail_controller.dart';
import 'package:hopak_frontend/services/admin_service.dart';
import 'package:hopak_frontend/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> _user({
  int id = 5,
  String? username = 'bank owner',
  String role = 'owner',
  String status = 'active',
  Object? isVerified = 1,
  String? suspensionReason,
  String? suspendedAt,
}) => {
  'id': id,
  'username': username,
  'phone': '0812345678',
  'role': role,
  'status': status,
  'is_verified': isVerified,
  'created_at': '2026-11-10T10:00:00.000Z',
  'suspension_reason': suspensionReason,
  'suspended_at': suspendedAt,
};

/// ตั้งค่า MockClient ให้ตอบตาม path และบันทึก request ทั้งหมดไว้ใน [log]
AdminService _admin({
  required List<http.Request> log,
  List<Map<String, dynamic>> users = const [],
  List<Map<String, dynamic>> dorms = const [],
  int actionStatus = 200,
}) {
  final api = ApiClient(
    tokenProvider: () => 'admin-token',
    client: MockClient((req) async {
      log.add(req);
      final path = req.url.path;
      if (req.method == 'GET' && path == '/api/admin/users') {
        return _json({'users': users});
      }
      if (req.method == 'GET' && path == '/api/admin/dormitories') {
        return _json({'dormitories': dorms});
      }
      if (req.method == 'POST' && path.startsWith('/api/admin/users/')) {
        return actionStatus == 200
            ? _json({'ok': true})
            : _json({'error': 'boom'}, actionStatus);
      }
      return _json({'error': 'not found'}, 404);
    }),
  );
  return AdminService(api);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('AdminUserDetailController.load', () {
    test('พบผู้ใช้เจ้าของและโหลดเฉพาะหอของคนนั้น', () async {
      final log = <http.Request>[];
      final c = AdminUserDetailController(
        _admin(
          log: log,
          users: [_user(id: 5), _user(id: 6, username: 'other')],
          dorms: [
            {'id': 1, 'name': 'หอ A', 'owner_id': 5, 'status': 'published'},
            {'id': 2, 'name': 'หอ B', 'owner_id': 6, 'status': 'pending'},
            {'id': 3, 'name': 'หอ C', 'owner_id': 5, 'status': 'hidden'},
          ],
        ),
        userId: 5,
      );

      expect(await c.load(), isTrue);

      expect(c.user?['id'], 5);
      expect(c.notFound, isFalse);
      expect(c.isOwner, isTrue);
      expect(c.dorms.map((d) => d['id']), [1, 3]);
      expect(log.map((r) => r.url.path), [
        '/api/admin/users',
        '/api/admin/dormitories',
      ]);
    });

    test('ผู้ใช้ที่ไม่ใช่เจ้าของไม่เรียก API หอ และ dorms ว่าง', () async {
      final log = <http.Request>[];
      final c = AdminUserDetailController(
        _admin(log: log, users: [_user(id: 7, role: 'student')]),
        userId: 7,
      );

      expect(await c.load(), isTrue);

      expect(c.isOwner, isFalse);
      expect(c.dorms, isEmpty);
      expect(log.map((r) => r.url.path), ['/api/admin/users']);
    });

    test('ไม่พบผู้ใช้ → notFound และ load คืน false โดยไม่มี error', () async {
      final c = AdminUserDetailController(
        _admin(log: [], users: [_user(id: 1)]),
        userId: 99,
      );

      expect(await c.load(), isFalse);

      expect(c.notFound, isTrue);
      expect(c.user, isNull);
      expect(c.error, isNull);
      expect(c.loading, isFalse);
    });

    test('API ล้มเหลว → เก็บ error และ load คืน false', () async {
      final api = ApiClient(
        tokenProvider: () => 'admin-token',
        client: MockClient((req) async => _json({'error': 'down'}, 500)),
      );
      final c = AdminUserDetailController(AdminService(api), userId: 5);

      expect(await c.load(), isFalse);

      expect(c.error, isNotNull);
      expect(c.notFound, isFalse);
      expect(c.loading, isFalse);
    });
  });

  group('AdminUserDetailController ข้อมูลที่แสดง', () {
    test('ชื่อ ตัวย่อ และค่าเริ่มต้นเมื่อไม่มีชื่อ', () async {
      final named = AdminUserDetailController(
        _admin(log: [], users: [_user(id: 5, username: 'bank owner')]),
        userId: 5,
      );
      await named.load();
      expect(named.displayName, 'bank owner');
      expect(named.initials, 'BO');

      final unnamed = AdminUserDetailController(
        _admin(log: [], users: [_user(id: 8, username: '   ', role: 'student')]),
        userId: 8,
      );
      await unnamed.load();
      expect(unnamed.displayName, 'User #8');
      expect(unnamed.initials, '?');
    });

    test('ก่อนโหลดใช้ค่าว่างปลอดภัย', () {
      final c = AdminUserDetailController(_admin(log: []), userId: 5);

      expect(c.displayName, 'User #5');
      expect(c.initials, '?');
      expect(c.phone, '-');
      expect(c.role, '-');
      expect(c.joined, '-');
      expect(c.canSuspend, isFalse);
      expect(c.suspendedAt, isNull);
      expect(c.suspensionReason, isNull);
    });

    test('is_verified รับได้ทั้ง 1 และ true', () async {
      final one = AdminUserDetailController(
        _admin(log: [], users: [_user(id: 5, isVerified: 1)]),
        userId: 5,
      );
      await one.load();
      expect(one.isVerified, isTrue);

      final flag = AdminUserDetailController(
        _admin(log: [], users: [_user(id: 5, isVerified: true)]),
        userId: 5,
      );
      await flag.load();
      expect(flag.isVerified, isTrue);

      final no = AdminUserDetailController(
        _admin(log: [], users: [_user(id: 5, isVerified: 0)]),
        userId: 5,
      );
      await no.load();
      expect(no.isVerified, isFalse);
    });

    test('ข้อมูลการระงับมาจาก API เมื่อผู้ใช้ถูกระงับ', () async {
      final c = AdminUserDetailController(
        _admin(
          log: [],
          users: [
            _user(
              id: 5,
              status: 'suspended',
              suspensionReason: 'รายงานซ้ำ',
              suspendedAt: '2026-11-12T08:30:00.000Z',
            ),
          ],
        ),
        userId: 5,
      );
      await c.load();

      expect(c.isSuspended, isTrue);
      expect(c.status, 'Suspended');
      expect(c.suspensionReason, 'รายงานซ้ำ');
      expect(c.suspendedAt, isNotNull);
      expect(c.canSuspend, isFalse);
    });

    test('canSuspend: นักศึกษาที่ active ระงับได้ แอดมินระงับไม่ได้', () async {
      final student = AdminUserDetailController(
        _admin(log: [], users: [_user(id: 5, role: 'student')]),
        userId: 5,
      );
      await student.load();
      expect(student.canSuspend, isTrue);
      expect(student.role, 'Student');

      final admin = AdminUserDetailController(
        _admin(log: [], users: [_user(id: 5, role: 'admin')]),
        userId: 5,
      );
      await admin.load();
      expect(admin.isAdmin, isTrue);
      expect(admin.canSuspend, isFalse);
    });
  });

  group('AdminUserDetailController suspend / restore', () {
    test('เหตุผลว่างหรือยาวเกินไม่ส่ง request', () async {
      final log = <http.Request>[];
      final c = AdminUserDetailController(_admin(log: log), userId: 5);

      expect(await c.suspend('   '), isFalse);
      expect(c.error, isA<ApiException>());
      expect(await c.suspend('x' * 301), isFalse);
      expect(log, isEmpty);
    });

    test('ระงับสำเร็จ ส่งเหตุผลที่ trim แล้วและโหลดข้อมูลใหม่', () async {
      final log = <http.Request>[];
      final c = AdminUserDetailController(
        _admin(log: log, users: [_user(id: 5, role: 'student')]),
        userId: 5,
      );
      await c.load();
      log.clear();

      expect(await c.suspend('  รายงานซ้ำ  '), isTrue);

      expect(log.first.method, 'POST');
      expect(log.first.url.path, '/api/admin/users/5/suspend');
      expect(jsonDecode(log.first.body), {'reason': 'รายงานซ้ำ'});
      expect(log.last.method, 'GET');
      expect(log.last.url.path, '/api/admin/users');
      expect(c.busy, isFalse);
      expect(c.error, isNull);
    });

    test('ยกเลิกการระงับสำเร็จเรียก restore และโหลดใหม่', () async {
      final log = <http.Request>[];
      final c = AdminUserDetailController(
        _admin(log: log, users: [_user(id: 5, status: 'suspended')]),
        userId: 5,
      );
      await c.load();
      log.clear();

      expect(await c.restore(), isTrue);

      expect(log.map((r) => '${r.method} ${r.url.path}'), [
        'POST /api/admin/users/5/restore',
        'GET /api/admin/users',
        'GET /api/admin/dormitories',
      ]);
    });

    test('API ล้มเหลวตอนระงับ → คืน false เก็บ error และไม่โหลดซ้ำ', () async {
      final log = <http.Request>[];
      final c = AdminUserDetailController(
        _admin(log: log, users: [_user(id: 5)], actionStatus: 409),
        userId: 5,
      );
      await c.load();
      log.clear();

      expect(await c.suspend('เหตุผล'), isFalse);

      expect(c.error, isNotNull);
      expect(c.busy, isFalse);
      expect(log.map((r) => r.method), ['POST']);
    });
  });

  group('AdminUserDetailController.formatDate', () {
    test('แปลง ISO และรูปแบบ MySQL เป็น yyyy-mm-dd', () {
      final iso = AdminUserDetailController.formatDate('2026-11-10T10:00:00.000Z');
      expect(iso, matches(RegExp(r'^2026-11-(09|10|11)$')));
      expect(
        AdminUserDetailController.formatDate('2026-03-05 12:00:00'),
        '2026-03-05',
      );
    });

    test('ค่าว่างแสดง "-" และข้อความที่แปลงไม่ได้คืนค่าเดิม', () {
      expect(AdminUserDetailController.formatDate(null), '-');
      expect(AdminUserDetailController.formatDate(''), '-');
      expect(AdminUserDetailController.formatDate('ไม่ใช่วันที่'), 'ไม่ใช่วันที่');
    });
  });
}
