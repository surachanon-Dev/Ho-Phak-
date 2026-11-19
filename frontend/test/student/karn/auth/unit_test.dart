// ผู้รับผิดชอบ: Karn (นักศึกษา)
// unit test: LoginController และ RegisterController (เข้าสู่ระบบ / สมัครสมาชิก)
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:hopak_frontend/modules/auth/login/controller/login_controller.dart';
import 'package:hopak_frontend/modules/auth/register/controller/register_controller.dart';
import 'package:hopak_frontend/services/auth_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_backend.dart';

class MockAuthService extends Mock implements AuthService {}

const form = RegisterInput(
  firstName: ' Karn ',
  surname: 'Student',
  phone: ' 0812345678 ',
  password: 'secret123',
  confirmPassword: 'secret123',
);

void main() {
  late MockAuthService auth;

  setUp(() => auth = MockAuthService());

  group('LoginController', () {
    test('1. phone and password must not be empty', () {
      expect(LoginController.validatePhone('  '), isNotNull);
      expect(LoginController.validatePhone('0812345678'), isNull);
      expect(LoginController.validatePassword(''), isNotNull);
      expect(LoginController.validatePassword('secret'), isNull);
    });

    test('2. correct login keeps the user', () async {
      when(() => auth.login(any(), any()))
          .thenAnswer((_) async => fakeUser(username: 'karn'));
      final c = LoginController(auth);

      expect(await c.submit(phone: ' 0812345678 ', password: 'secret'), isTrue);

      verify(() => auth.login('0812345678', 'secret')).called(1);
      expect(c.user?.username, 'karn');
      expect(c.loading, isFalse);
    });

    test('3. wrong password shows a message in the form', () async {
      when(() => auth.login(any(), any())).thenAnswer((_) async => null);
      final c = LoginController(auth);

      expect(await c.submit(phone: '0812345678', password: 'wrong'), isFalse);

      expect(c.error, LoginController.invalidCredentialsMessage);
      expect(c.failure, isNull);
    });

    test('4. suspended account becomes a failure for the screen', () async {
      when(() => auth.login(any(), any()))
          .thenThrow(ApiException(403, 'This account is suspended.'));
      final c = LoginController(auth);

      expect(await c.submit(phone: '0812345678', password: 'secret'), isFalse);

      expect(c.failure, isA<ApiException>());
      expect(c.error, isNull);
    });

    test('5. empty form is not sent', () async {
      final c = LoginController(auth);

      expect(await c.submit(phone: '', password: ''), isFalse);

      verifyNever(() => auth.login(any(), any()));
    });
  });

  group('RegisterController', () {
    test('6. password needs 8 characters and the confirmation must match', () {
      expect(RegisterController.validatePassword('short'), isNotNull);
      expect(RegisterController.validatePassword('long enough'), isNull);
      expect(RegisterController.validateConfirm('abc', 'abd'), isNotNull);
      expect(RegisterController.validateConfirm('abc', 'abc'), isNull);
    });

    test('7. sign up sends the trimmed phone and names', () async {
      when(
        () => auth.register(
          any(),
          any(),
          any(),
          firstName: any(named: 'firstName'),
          surname: any(named: 'surname'),
        ),
      ).thenAnswer((_) async {});
      final c = RegisterController(auth);

      expect(await c.submit(form), isTrue);

      verify(
        () => auth.register(
          '0812345678',
          'secret123',
          'secret123',
          firstName: 'Karn',
          surname: 'Student',
        ),
      ).called(1);
      expect(c.done, isTrue);
    });

    test('8. phone already used shows a message in the form', () async {
      when(
        () => auth.register(
          any(),
          any(),
          any(),
          firstName: any(named: 'firstName'),
          surname: any(named: 'surname'),
        ),
      ).thenThrow(ApiException(409, 'เบอร์นี้ถูกใช้แล้ว'));
      final c = RegisterController(auth);

      expect(await c.submit(form), isFalse);

      expect(c.error, RegisterController.duplicatePhoneMessage);
      expect(c.failure, isNull);
    });

    test('9. other server errors become a failure', () async {
      when(
        () => auth.register(
          any(),
          any(),
          any(),
          firstName: any(named: 'firstName'),
          surname: any(named: 'surname'),
        ),
      ).thenThrow(ApiException(500, 'Server error'));
      final c = RegisterController(auth);

      expect(await c.submit(form), isFalse);

      expect(c.failure, isA<ApiException>());
      expect(c.loading, isFalse);
    });
  });
}
