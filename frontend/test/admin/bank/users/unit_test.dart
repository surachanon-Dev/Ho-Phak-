// ผู้รับผิดชอบ: Bank (แอดมิน)
// unit test: AdminUsersController (รายชื่อผู้ใช้ ระงับ / ยกเลิกระงับ)
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:hopak_frontend/services/admin_service.dart';
import 'package:hopak_frontend/modules/admin/users/controller/admin_users_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockAdminService extends Mock implements AdminService {}

void main() {
  late MockAdminService service;
  late AdminUsersController controller;

  setUp(() {
    service = MockAdminService();
    controller = AdminUsersController(service);
    when(
      () => service.allUsers(
        role: any(named: 'role'),
        status: any(named: 'status'),
      ),
    ).thenAnswer(
      (_) async => [
        {'id': 2, 'username': 'bank', 'role': 'owner', 'status': 'active'},
      ],
    );
  });

  test('1. load sends the filters and keeps the users', () async {
    expect(await controller.load(role: 'owner', status: 'active'), isTrue);

    verify(() => service.allUsers(role: 'owner', status: 'active')).called(1);
    expect(controller.users.single['username'], 'bank');
  });

  test('2. suspend needs a reason and sends it trimmed', () async {
    when(() => service.suspendUser(any(), any())).thenAnswer((_) async {});

    expect(await controller.suspend(2, '   '), isFalse);
    verifyNever(() => service.suspendUser(any(), any()));

    expect(await controller.suspend(2, ' spam '), isTrue);
    verify(() => service.suspendUser(2, 'spam')).called(1);
  });

  test('3. restore that fails returns false and keeps the error', () async {
    when(() => service.restoreUser(2))
        .thenThrow(ApiException(500, 'Server error'));

    expect(await controller.restore(2), isFalse);

    expect(controller.error, isA<ApiException>());
    expect(controller.busy, isFalse);
  });

  test('4. restore lifts the suspension and reloads the users', () async {
    when(() => service.restoreUser(2)).thenAnswer((_) async {});

    expect(await controller.restore(2), isTrue);

    verify(() => service.restoreUser(2)).called(1);
    verify(() => service.allUsers()).called(1);
  });
}
