import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/owner/services/api_owner_extras.dart';
import 'package:hopak_frontend/features/owner/services/owner_account_service.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:hopak_frontend/features/auth/services/auth_service.dart';
import 'package:hopak_frontend/core/network/token_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hopak_frontend/features/owner/models/owner_profile.dart';
import 'package:hopak_frontend/features/owner/controllers/owner_profile_controller.dart';
import 'package:hopak_frontend/features/owner/controllers/edit_profile_controller.dart';
import 'package:hopak_frontend/features/owner/controllers/change_password_controller.dart';
import 'package:hopak_frontend/features/owner/controllers/notification_settings_controller.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

/// สร้าง OwnerAccountService ที่ใช้ ApiOwnerExtras กับ MockClient
OwnerAccountService _account(
  http.Response Function(http.Request req) handler,
  List<http.Request> log,
) {
  final api = ApiClient(
    tokenProvider: () => 't',
    client: MockClient((req) async {
      log.add(req);
      return handler(req);
    }),
  );
  return OwnerAccountService(ApiOwnerExtras(api));
}

const _profileJson = {
  'profile': {
    'first_name': 'สมชาย',
    'surname': 'ใจดี',
    'phone': '0855500002',
    'pending_phone': null,
    'photo': null,
  },
};

OwnerProfile _original() => const OwnerProfile(
  firstName: 'สมชาย',
  surname: 'ใจดี',
  phone: '0855500002',
);

void main() {
  group('OwnerProfileController', () {
    test('load ใช้โปรไฟล์จาก API', () async {
      final log = <http.Request>[];
      final c = OwnerProfileController(
        account: _account((req) => _json(_profileJson), log),
        auth: AuthService(ApiClient(tokenProvider: () => null), TokenStore()),
        fallbackName: 'qa_owner',
      );

      expect(await c.load(), isTrue);

      expect(c.profile.fullName, 'สมชาย ใจดี');
      expect(c.profile.phone, '0855500002');
      expect(log.single.url.path, '/api/me/profile');
    });

    test('load ล้มเหลวคืน false และเก็บ error', () async {
      final log = <http.Request>[];
      final c = OwnerProfileController(
        account: _account((req) => _json({'message': 'x'}, 500), log),
        auth: AuthService(ApiClient(tokenProvider: () => null), TokenStore()),
        fallbackName: 'qa_owner',
      );

      expect(await c.load(), isFalse);
      expect(c.error, isA<ApiException>());
      expect(c.loading, isFalse);
    });
  });

  group('EditProfileController', () {
    test('ยังไม่มีการเปลี่ยนแปลงจึงบันทึกไม่ได้', () {
      final c = EditProfileController(
        original: _original(),
        account: _account((req) => _json({}), []),
      );
      expect(c.dirty, isFalse);
      expect(c.canSave, isFalse);
      expect(c.phoneChanged, isFalse);
    });

    test('แก้ชื่อแล้วบันทึกได้ และ dirty เป็น true', () {
      final c = EditProfileController(
        original: _original(),
        account: _account((req) => _json({}), []),
      );
      c.setFirstName('สมหมาย');
      expect(c.dirty, isTrue);
      expect(c.canSave, isTrue);
      expect(c.phoneChanged, isFalse);
    });

    test('ชื่อว่างไม่ผ่านการตรวจ', () {
      final c = EditProfileController(
        original: _original(),
        account: _account((req) => _json({}), []),
      );
      c.setFirstName('   ');
      expect(c.validateFirstName(), 'Enter your first name');
      expect(c.isValid, isFalse);
    });

    test('เปลี่ยนเบอร์ต้องใส่รหัสผ่าน', () {
      final c = EditProfileController(
        original: _original(),
        account: _account((req) => _json({}), []),
      );
      c.setPhone('0855500099');
      expect(c.phoneChanged, isTrue);
      expect(c.validatePassword(), isNotNull);
      expect(c.isValid, isFalse);
      expect(
        c.canSave,
        isTrue,
        reason: 'กดได้เพื่อให้แสดง error ของช่องรหัสผ่าน',
      );

      c.setPassword('pw12345678');
      expect(c.validatePassword(), isNull);
      expect(c.canSave, isTrue);
    });

    test('เบอร์รูปแบบผิดไม่ผ่าน', () {
      final c = EditProfileController(
        original: _original(),
        account: _account((req) => _json({}), []),
      );
      c.setPhone('abc');
      expect(c.validatePhone(), isNotNull);
      expect(c.isValid, isFalse);
    });

    test('save ส่ง photoBase64 เป็น null เมื่อไม่ได้เปลี่ยนรูป', () async {
      final log = <http.Request>[];
      final c = EditProfileController(
        original: _original(),
        account: _account((req) {
          if (req.method == 'PUT') return _json(_profileJson);
          return _json(_profileJson);
        }, log),
      );
      c.setSurname('ดีมาก');

      expect(await c.save(), isTrue);

      final body =
          jsonDecode(log.firstWhere((r) => r.method == 'PUT').body) as Map;
      expect(
        body.containsKey('photo'),
        isFalse,
        reason: 'ไม่ได้เปลี่ยนรูป จึงไม่ส่ง photo',
      );
      expect(body['surname'], 'ดีมาก');
      expect(c.saved?.phone, '0855500002');
    });

    test('ลบรูปส่งเป็นสตริงว่าง', () async {
      final log = <http.Request>[];
      final c = EditProfileController(
        original: _original(),
        account: _account((req) => _json(_profileJson), log),
      );
      c.setPhoto(null);

      await c.save();

      final body =
          jsonDecode(log.firstWhere((r) => r.method == 'PUT').body) as Map;
      expect(body['photo'], '');
    });

    test('save ล้มเหลวเก็บ error และ saving เป็น false', () async {
      final c = EditProfileController(
        original: _original(),
        account: _account((req) => _json({'message': 'x'}, 403), []),
      );
      c.setFirstName('ใหม่');

      expect(await c.save(), isFalse);
      expect(c.error, isA<ApiException>());
      expect(c.saving, isFalse);
    });
  });

  group('ChangePasswordController', () {
    test('ตรวจกติกาตามลำดับ: ว่าง, สั้นเกิน, ซ้ำรหัสเดิม, ไม่ตรงกัน', () {
      final c = ChangePasswordController(_account((req) => _json({}), []));
      expect(c.validateCurrent(), isNotNull);

      c.setCurrent('oldpass123');
      c.setNext('short');
      expect(c.validateNext(), isNotNull);

      c.setNext('oldpass123');
      expect(c.validateNext(), 'New password must be different');

      c.setNext('newpass1234');
      c.setConfirm('newpass1235');
      expect(c.validateConfirm(), 'Passwords do not match');

      c.setConfirm('newpass1234');
      expect(c.isValid, isTrue);
    });

    test('submit สำเร็จส่ง current/next และคืน true', () async {
      final log = <http.Request>[];
      final c = ChangePasswordController(
        _account((req) => _json({'message': 'ok'}), log),
      );
      c.setCurrent('oldpass123');
      c.setNext('newpass1234');
      c.setConfirm('newpass1234');

      expect(await c.submit(), isTrue);

      final body = jsonDecode(log.single.body) as Map;
      expect(body, {
        'current_password': 'oldpass123',
        'new_password': 'newpass1234',
      });
      expect(log.single.url.path, '/api/me/password');
    });

    test('submit ไม่ยิง request เมื่อฟอร์มไม่ผ่าน', () async {
      final log = <http.Request>[];
      final c = ChangePasswordController(_account((req) => _json({}), log));
      expect(await c.submit(), isFalse);
      expect(log, isEmpty);
    });

    test('รหัสปัจจุบันผิด (403) เก็บ error', () async {
      final c = ChangePasswordController(
        _account(
          (req) => _json({'message': 'password ปัจจุบันไม่ถูกต้อง'}, 403),
          [],
        ),
      );
      c.setCurrent('wrong-pass');
      c.setNext('newpass1234');
      c.setConfirm('newpass1234');

      expect(await c.submit(), isFalse);
      expect(c.error, isA<ApiException>());
      expect(c.saving, isFalse);
    });
  });

  group('NotificationSettingsController', () {
    test('load แล้วสลับค่าและบันทึกค่าใหม่', () async {
      final log = <http.Request>[];
      final c = NotificationSettingsController(
        _account((req) {
          if (req.method == 'PUT')
            return _json({
              'messages': true,
              'approvals': true,
              'reviews': true,
            });
          return _json({'messages': true, 'approvals': true, 'reviews': false});
        }, log),
      );

      expect(await c.load(), isTrue);
      expect(c.prefs?.reviews, isFalse);

      final ok = await c.update(c.prefs!.copyWith(reviews: true));

      expect(ok, isTrue);
      expect(c.prefs?.reviews, isTrue);
      final put = log.firstWhere((r) => r.method == 'PUT');
      expect(jsonDecode(put.body), {
        'messages': true,
        'approvals': true,
        'reviews': true,
      });
    });

    test('บันทึกไม่สำเร็จย้อนกลับเป็นค่าเดิม', () async {
      final c = NotificationSettingsController(
        _account((req) {
          if (req.method == 'PUT') return _json({'message': 'x'}, 500);
          return _json({'messages': true, 'approvals': true, 'reviews': false});
        }, []),
      );
      await c.load();

      final ok = await c.update(c.prefs!.copyWith(messages: false));

      expect(ok, isFalse);
      expect(c.prefs?.messages, isTrue, reason: 'ย้อนกลับเป็นค่าก่อนแก้');
      expect(c.error, isA<ApiException>());
    });

    test('load ล้มเหลวคืน false และ prefs เป็น null', () async {
      final c = NotificationSettingsController(
        _account((req) => _json({'message': 'x'}, 500), []),
      );
      expect(await c.load(), isFalse);
      expect(c.prefs, isNull);
    });
  });
}
