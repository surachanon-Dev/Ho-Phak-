// ผู้รับผิดชอบ: Kren (เจ้าของหอ)
// unit test: ChangePasswordController และกติการหัสผ่าน (OwnerAccountRules)
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:hopak_frontend/modules/owner/change_password/controller/change_password_controller.dart';
import 'package:hopak_frontend/modules/owner/validation/owner_account_rules.dart';
import 'package:hopak_frontend/services/owner_account_service.dart';
import 'package:mocktail/mocktail.dart';

class MockOwnerAccountService extends Mock implements OwnerAccountService {}

void main() {
  late MockOwnerAccountService account;
  late ChangePasswordController controller;

  setUp(() {
    account = MockOwnerAccountService();
    controller = ChangePasswordController(account);
  });

  void fill({
    String current = 'oldpass1',
    String next = 'newpass123',
    String? confirm,
  }) {
    controller
      ..setCurrent(current)
      ..setNext(next)
      ..setConfirm(confirm ?? next);
  }

  test('1. an empty form is invalid', () {
    expect(controller.isValid, isFalse);
    expect(controller.validateCurrent(), 'Enter your current password');
    expect(controller.validateNext(), 'Use at least 8 characters');
  });

  test('2. a short new password is rejected', () {
    fill(next: 'short');

    expect(controller.validateNext(), 'Use at least 8 characters');
  });

  test('3. the new password must differ from the current one', () {
    fill(current: 'samepass1', next: 'samepass1');

    expect(controller.validateNext(), 'New password must be different');
  });

  test('4. a confirmation that does not match is rejected', () {
    fill(confirm: 'different');

    expect(controller.validateConfirm(), 'Passwords do not match');
    expect(controller.isValid, isFalse);
  });

  test('5. a valid form sends the current and the new password', () async {
    when(
      () => account.changePassword(
        current: any(named: 'current'),
        next: any(named: 'next'),
      ),
    ).thenAnswer((_) async {});
    fill();

    expect(controller.isValid, isTrue);
    expect(await controller.submit(), isTrue);

    verify(
      () => account.changePassword(current: 'oldpass1', next: 'newpass123'),
    ).called(1);
    expect(controller.saving, isFalse);
  });

  test('6. an invalid form is not sent', () async {
    fill(confirm: 'different');

    expect(await controller.submit(), isFalse);

    verifyNever(
      () => account.changePassword(
        current: any(named: 'current'),
        next: any(named: 'next'),
      ),
    );
  });

  test('7. a wrong current password keeps the backend error', () async {
    when(
      () => account.changePassword(
        current: any(named: 'current'),
        next: any(named: 'next'),
      ),
    ).thenThrow(ApiException(400, 'Current password is incorrect'));
    fill();

    expect(await controller.submit(), isFalse);

    expect(controller.error, isA<ApiException>());
    expect(controller.saving, isFalse);
  });

  group('OwnerAccountRules', () {
    test('8. phone accepts digits, + - and spaces, 9 to 15 long', () {
      expect(OwnerAccountRules.phone(''), 'Enter your phone number');
      expect(OwnerAccountRules.phone('12345'), 'Enter a valid phone number');
      expect(OwnerAccountRules.phone('abc123456789'), isNotNull);
      expect(OwnerAccountRules.phone('0812345678'), isNull);
      expect(OwnerAccountRules.phone('+66 81 234 5678'), isNull);
    });

    test('9. a password is needed only when the phone changes', () {
      expect(
        OwnerAccountRules.passwordForPhoneChange('', phoneChanged: false),
        isNull,
      );
      expect(
        OwnerAccountRules.passwordForPhoneChange('', phoneChanged: true),
        'Enter your password to change your phone number',
      );
      expect(
        OwnerAccountRules.passwordForPhoneChange('secret', phoneChanged: true),
        isNull,
      );
    });
  });
}
