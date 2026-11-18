// ผู้รับผิดชอบ: Karn (นักศึกษา)
// ไฟล์นี้เป็นเทสต์ unit ของ controller ที่ระบุในชื่อ group
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/auth/login/login_controller.dart';
import 'package:hopak_frontend/features/auth/register/register_controller.dart';
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

class Harness {
  Harness(this.handler) {
    api = ApiClient(
      tokenProvider: () => tokens.token,
      client: MockClient((req) async {
        requests.add(req);
        return handler(req);
      }),
    );
    tokens = TokenStore();
    auth = AuthService(api, tokens);
  }

  final http.Response Function(http.Request req) handler;
  final List<http.Request> requests = [];
  late final ApiClient api;
  late final TokenStore tokens;
  late final AuthService auth;
}

Map<String, dynamic> _me({String role = 'student', String status = 'active'}) => {
  'user': {
    'id': 20,
    'username': 'qa_student',
    'role': role,
    'status': status,
    'is_verified': 0,
  },
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('LoginController validators', () {
    test('เบอร์ว่างหรือมีแต่ช่องว่างให้ error', () {
      expect(LoginController.validatePhone(null), isNotNull);
      expect(LoginController.validatePhone('   '), isNotNull);
      expect(LoginController.validatePhone('0855500001'), isNull);
    });

    test('รหัสผ่านว่างให้ error แต่ช่องว่างล้วนยังถือว่ากรอกแล้ว', () {
      expect(LoginController.validatePassword(null), isNotNull);
      expect(LoginController.validatePassword(''), isNotNull);
      expect(LoginController.validatePassword(' '), isNull);
    });
  });

  group('LoginController.submit', () {
    test('login สำเร็จ เก็บ token และคืน user', () async {
      final h = Harness((req) {
        if (req.url.path == '/api/login') {
          return _json({
            'token': 'tok-123',
            'user': {'id': 20, 'role': 'student', 'is_verified': 0},
          });
        }
        return _json(_me());
      });
      final c = LoginController(h.auth);

      final ok = await c.submit(phone: ' 0855500001 ', password: 'pw12345678');

      expect(ok, isTrue);
      expect(c.user?.role, 'student');
      expect(c.error, isNull);
      expect(c.failure, isNull);
      expect(c.loading, isFalse);
      expect(await h.tokens.token, 'tok-123');
      final login = h.requests.first;
      expect(jsonDecode(login.body), {'phone': '0855500001', 'password': 'pw12345678'});
    });

    test('รหัสผิด (401) แสดงข้อความในฟอร์ม ไม่ถือเป็น failure', () async {
      final h = Harness((req) => _json({'message': 'เบอร์หรือ password ไม่ถูกต้อง'}, 401));
      final c = LoginController(h.auth);

      final ok = await c.submit(phone: '0855500001', password: 'wrong');

      expect(ok, isFalse);
      expect(c.error, LoginController.invalidCredentialsMessage);
      expect(c.failure, isNull);
      expect(c.user, isNull);
    });

    test('บัญชีถูกระงับ (403) ได้ failure และไม่เก็บ token', () async {
      final h = Harness((req) {
        if (req.url.path == '/api/login') {
          return _json({'token': 'tok', 'user': {'id': 20}});
        }
        return _json(_me(status: 'suspended'));
      });
      final c = LoginController(h.auth);

      final ok = await c.submit(phone: '0855500001', password: 'pw12345678');

      expect(ok, isFalse);
      expect(c.failure, isA<ApiException>());
      expect((c.failure as ApiException).message, contains('ถูกระงับ'));
      expect(await h.tokens.token, isNull);
    });

    test('ฟอร์มว่างไม่เรียก API', () async {
      final h = Harness((req) => _json({}));
      final c = LoginController(h.auth);

      expect(await c.submit(phone: '', password: 'x'), isFalse);
      expect(await c.submit(phone: '0855500001', password: ''), isFalse);
      expect(h.requests, isEmpty);
    });

    test('เชื่อมต่อไม่ได้ เก็บ failure และ loading กลับเป็น false', () async {
      final h = Harness((req) => _json({'message': 'x'}, 500));
      final c = LoginController(h.auth);

      final ok = await c.submit(phone: '0855500001', password: 'pw12345678');

      expect(ok, isFalse);
      expect(c.failure, isA<ApiException>());
      expect(c.loading, isFalse);
    });

    test('notify ตอนเริ่มกำลังโหลดและตอนจบ', () async {
      final h = Harness((req) {
        if (req.url.path == '/api/login') {
          return _json({'token': 't', 'user': {'id': 20}});
        }
        return _json(_me());
      });
      final c = LoginController(h.auth);
      var notifications = 0;
      c.addListener(() => notifications++);

      await c.submit(phone: '0855500001', password: 'pw12345678');

      expect(notifications, 2);
    });
  });

  group('RegisterController', () {
    test('validateRequired ปฏิเสธช่องว่างล้วน', () {
      expect(RegisterController.validateRequired('  ', 'ต้องกรอก'), 'ต้องกรอก');
      expect(RegisterController.validateRequired('สมชาย', 'ต้องกรอก'), isNull);
    });

    test('validatePassword ต้องยาวอย่างน้อย 8 ตัว', () {
      expect(RegisterController.validatePassword('1234567'), isNotNull);
      expect(RegisterController.validatePassword('12345678'), isNull);
      expect(RegisterController.validatePassword(null), isNotNull);
    });

    test('validateConfirm ต้องตรงกับรหัสผ่าน', () {
      expect(RegisterController.validateConfirm('abc', 'abd'), isNotNull);
      expect(RegisterController.validateConfirm('abc', 'abc'), isNull);
    });

    test('submit สำเร็จ ส่ง phone, รหัส, confirm และ username ตามที่กำหนด', () async {
      final h = Harness((req) => _json({'message': 'สมัครสมาชิกสำเร็จ', 'id': 30}, 201));
      final c = RegisterController(h.auth);

      final ok = await c.submit(const RegisterInput(
        firstName: 'สมชาย',
        surname: 'ใจดี',
        phone: ' 0855500009 ',
        password: 'pw12345678',
        confirmPassword: 'pw12345678',
      ));

      expect(ok, isTrue);
      expect(c.done, isTrue);
      final body = jsonDecode(h.requests.single.body) as Map<String, dynamic>;
      expect(body['phone'], '0855500009');
      expect(body['password'], 'pw12345678');
      expect(body['confirmPassword'], 'pw12345678');
      expect(body['first_name'], 'สมชาย');
      expect(body['surname'], 'ใจดี');
      expect(body.containsKey('username'), isFalse);
      expect(h.requests.single.url.path, '/api/auth/register');
    });

    test('เบอร์ซ้ำ (409) แสดงข้อความในฟอร์ม ไม่ใช่ failure', () async {
      final h = Harness((req) => _json({'message': 'เบอร์นี้ถูกใช้แล้ว'}, 409));
      final c = RegisterController(h.auth);

      final ok = await c.submit(const RegisterInput(
        firstName: 'a',
        surname: 'b',
        phone: '0855500001',
        password: 'pw12345678',
        confirmPassword: 'pw12345678',
      ));

      expect(ok, isFalse);
      expect(c.error, RegisterController.duplicatePhoneMessage);
      expect(c.failure, isNull);
      expect(c.done, isFalse);
    });

    test('ข้อผิดพลาด 409 อื่นที่ไม่ใช่เรื่องเบอร์ ไปเป็น failure', () async {
      expect(
        RegisterController.isDuplicatePhone(
          ApiException(409, 'ข้อมูลซ้ำกับที่มีอยู่แล้ว'),
        ),
        isFalse,
      );
    });

    test('isDuplicatePhone ปฏิเสธข้อผิดพลาดที่ไม่ใช่ ApiException', () {
      expect(RegisterController.isDuplicatePhone(Exception('เบอร์')), isFalse);
    });

    test('server error ไป failure และ loading กลับเป็น false', () async {
      final h = Harness((req) => _json({'message': 'DB error'}, 500));
      final c = RegisterController(h.auth);

      final ok = await c.submit(const RegisterInput(
        firstName: 'a',
        surname: 'b',
        phone: '0855500001',
        password: 'pw12345678',
        confirmPassword: 'pw12345678',
      ));

      expect(ok, isFalse);
      expect(c.failure, isA<ApiException>());
      expect(c.loading, isFalse);
    });
  });
}
