// ผู้รับผิดชอบ: Bank (แอดมิน)
// unit test: AdminUserDetailController (รายละเอียดผู้ใช้ ระงับ รีเซ็ตรหัสผ่าน)
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/services/admin_service.dart';
import 'package:hopak_frontend/modules/admin/user_detail/controller/admin_user_detail_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockAdminService extends Mock implements AdminService {}

void main() {
  late MockAdminService service;

  void usersAre(List<Map<String, dynamic>> users) {
    when(() => service.allUsers()).thenAnswer((_) async => users);
  }

  setUp(() {
    service = MockAdminService();
    when(() => service.allDormitories()).thenAnswer(
      (_) async => [
        {'id': 1, 'name': 'My Dorm', 'owner_id': 5},
        {'id': 2, 'name': 'Other Dorm', 'owner_id': 9},
      ],
    );
  });

  test('1. owner is loaded with only their own dorms', () async {
    usersAre([
      {'id': 5, 'username': 'bank owner', 'role': 'owner', 'status': 'active'},
    ]);
    final controller = AdminUserDetailController(service, userId: 5);

    expect(await controller.load(), isTrue);

    expect(controller.displayName, 'bank owner');
    expect(controller.isOwner, isTrue);
    expect(controller.dorms.map((d) => d['name']), ['My Dorm']);
  });

  test('2. user that does not exist is marked as not found', () async {
    usersAre([]);
    final controller = AdminUserDetailController(service, userId: 99);

    expect(await controller.load(), isFalse);

    expect(controller.notFound, isTrue);
    expect(controller.error, isNull);
  });

  test('3. an admin account cannot be suspended', () async {
    usersAre([
      {'id': 1, 'username': 'admin', 'role': 'admin', 'status': 'active'},
    ]);
    final controller = AdminUserDetailController(service, userId: 1);

    await controller.load();

    expect(controller.isAdmin, isTrue);
    expect(controller.canSuspend, isFalse);
  });

  test('4. resetPassword returns the temporary password', () async {
    usersAre([
      {'id': 7, 'username': 'beam', 'role': 'student', 'status': 'active'},
    ]);
    when(() => service.resetUserPassword(7))
        .thenAnswer((_) async => 'Ab3kPq9xYz');
    final controller = AdminUserDetailController(service, userId: 7);
    await controller.load();

    expect(await controller.resetPassword(), 'Ab3kPq9xYz');
  });

  test('5. suspend sends the trimmed reason and reloads the user', () async {
    usersAre([
      {'id': 7, 'username': 'beam', 'role': 'student', 'status': 'active'},
    ]);
    when(() => service.suspendUser(any(), any())).thenAnswer((_) async {});
    final controller = AdminUserDetailController(service, userId: 7);
    await controller.load();

    expect(await controller.suspend('  Spam  '), isTrue);

    verify(() => service.suspendUser(7, 'Spam')).called(1);
    verify(() => service.allUsers())
        .called(2); // โหลดครั้งแรก + โหลดใหม่หลังระงับ
  });

  test('6. restore lifts the suspension', () async {
    usersAre([
      {'id': 7, 'username': 'beam', 'role': 'student', 'status': 'suspended'},
    ]);
    when(() => service.restoreUser(7)).thenAnswer((_) async {});
    final controller = AdminUserDetailController(service, userId: 7);
    await controller.load();

    expect(await controller.restore(), isTrue);

    verify(() => service.restoreUser(7)).called(1);
  });

  test('7. resetPassword does nothing for an admin account', () async {
    usersAre([
      {'id': 1, 'username': 'admin', 'role': 'admin', 'status': 'active'},
    ]);
    final controller = AdminUserDetailController(service, userId: 1);
    await controller.load();

    expect(await controller.resetPassword(), isNull);

    verifyNever(() => service.resetUserPassword(any()));
  });
}
