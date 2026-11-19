// ผู้รับผิดชอบ: Kren (เจ้าของหอ)
// unit test: EditProfileController และ OwnerProfileController
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:hopak_frontend/model/owner_profile.dart';
import 'package:hopak_frontend/modules/owner/profile/controller/edit_profile_controller.dart';
import 'package:hopak_frontend/modules/owner/profile/controller/owner_profile_controller.dart';
import 'package:hopak_frontend/services/auth_service.dart';
import 'package:hopak_frontend/services/owner_account_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/owner_data.dart';

class MockOwnerAccountService extends Mock implements OwnerAccountService {}

class MockAuthService extends Mock implements AuthService {}

const original = OwnerProfile(
  firstName: 'Somchai',
  surname: 'Jaidee',
  phone: '0812345678',
);

void main() {
  late MockOwnerAccountService account;

  setUp(() => account = MockOwnerAccountService());

  EditProfileController edit() =>
      EditProfileController(original: original, account: account);

  void stubSave() {
    when(
      () => account.saveProfile(
        firstName: any(named: 'firstName'),
        surname: any(named: 'surname'),
        phone: any(named: 'phone'),
        password: any(named: 'password'),
        photoBase64: any(named: 'photoBase64'),
      ),
    ).thenAnswer(
      (_) async => const OwnerProfile(
        firstName: 'Somchai2',
        surname: 'Jaidee',
        phone: '0812345678',
      ),
    );
  }

  group('EditProfileController', () {
    test('1. starts with the current profile and nothing to save', () {
      final c = edit();

      expect(c.firstName, 'Somchai');
      expect(c.dirty, isFalse);
      expect(c.canSave, isFalse);
      expect(c.isValid, isTrue);
    });

    test('2. changing a name makes the form dirty', () {
      final c = edit()..setFirstName('Somchai2');

      expect(c.dirty, isTrue);
      expect(c.canSave, isTrue);
    });

    test('3. putting the old value back is not a change', () {
      final c = edit()
        ..setFirstName('Somchai2')
        ..setFirstName('Somchai');

      expect(c.dirty, isFalse);
    });

    test('4. changing the photo makes the form dirty, even removing it', () {
      final c = edit()..setPhoto(null);

      expect(c.photoChanged, isTrue);
      expect(c.dirty, isTrue);
    });

    test('5. blank names are rejected', () {
      final c = edit()
        ..setFirstName('  ')
        ..setSurname('');

      expect(c.validateFirstName(), 'Enter your first name');
      expect(c.validateSurname(), 'Enter your surname');
      expect(c.isValid, isFalse);
    });

    test('6. a new phone number needs the password', () {
      final c = edit()..setPhone('0819990000');

      expect(c.phoneChanged, isTrue);
      expect(
        c.validatePassword(),
        'Enter your password to change your phone number',
      );
      expect(c.isValid, isFalse);

      c.setPassword('secret123');
      expect(c.validatePassword(), isNull);
      expect(c.isValid, isTrue);
    });

    test('7. an invalid phone number is rejected', () {
      final c = edit()..setPhone('12');

      expect(c.validatePhone(), 'Enter a valid phone number');
    });

    test('8. save sends the trimmed values and keeps the result', () async {
      stubSave();
      final c = edit()..setFirstName('  Somchai2  ');

      expect(await c.save(), isTrue);

      verify(
        () => account.saveProfile(
          firstName: 'Somchai2',
          surname: 'Jaidee',
          phone: '0812345678',
          password: '',
          photoBase64: null,
        ),
      ).called(1);
      expect(c.saved!.firstName, 'Somchai2');
      expect(c.saving, isFalse);
    });

    test('9. a removed photo is sent as an empty string', () async {
      stubSave();
      final c = edit()..setPhoto(null);

      await c.save();

      verify(
        () => account.saveProfile(
          firstName: any(named: 'firstName'),
          surname: any(named: 'surname'),
          phone: any(named: 'phone'),
          password: any(named: 'password'),
          photoBase64: '',
        ),
      ).called(1);
    });

    test('10. save does nothing when nothing changed', () async {
      expect(await edit().save(), isFalse);

      verifyNever(
        () => account.saveProfile(
          firstName: any(named: 'firstName'),
          surname: any(named: 'surname'),
          phone: any(named: 'phone'),
          password: any(named: 'password'),
          photoBase64: any(named: 'photoBase64'),
        ),
      );
    });

    test('11. save with an invalid form is not sent', () async {
      final c = edit()
        ..setFirstName('')
        ..setSurname('X');

      expect(await c.save(), isFalse);
      expect(c.saved, isNull);
    });

    test('12. save that fails keeps the error', () async {
      when(
        () => account.saveProfile(
          firstName: any(named: 'firstName'),
          surname: any(named: 'surname'),
          phone: any(named: 'phone'),
          password: any(named: 'password'),
          photoBase64: any(named: 'photoBase64'),
        ),
      ).thenThrow(ApiException(409, 'Phone already used'));
      final c = edit()..setFirstName('Somchai2');

      expect(await c.save(), isFalse);

      expect(c.error, isA<ApiException>());
      expect(c.saved, isNull);
      expect(c.saving, isFalse);
    });
  });

  group('OwnerProfileController', () {
    late MockAuthService auth;
    late OwnerProfileController controller;

    setUp(() {
      auth = MockAuthService();
      controller = OwnerProfileController(
        account: account,
        auth: auth,
        fallbackName: 'somchai',
      );
    });

    test('13. load keeps the profile from the backend', () async {
      when(() => account.profile(fallbackName: 'somchai'))
          .thenAnswer((_) async => OwnerProfile.fromJson(ownerProfileJson()));

      expect(await controller.load(), isTrue);

      expect(controller.profile.firstName, 'Somchai');
      expect(controller.profile.phone, '0812345678');
      expect(controller.loading, isFalse);
    });

    test('14. load that fails keeps an empty profile and the error', () async {
      when(() => account.profile(fallbackName: any(named: 'fallbackName')))
          .thenThrow(ApiException(500, 'down'));

      expect(await controller.load(), isFalse);

      expect(controller.profile.firstName, isEmpty);
      expect(controller.error, isA<ApiException>());
    });

    test('15. logout signs out through the auth service', () async {
      when(() => auth.logout()).thenAnswer((_) async {});

      await controller.logout();

      verify(() => auth.logout()).called(1);
    });
  });
}
