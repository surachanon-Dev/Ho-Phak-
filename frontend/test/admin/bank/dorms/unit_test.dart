// ผู้รับผิดชอบ: Bank (แอดมิน)
// unit test: AdminDormsController (ตรวจหอ อนุมัติ / ปฏิเสธ / ระงับ)
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/modules/admin/dorms/controller/admin_dorms_controller.dart';
import 'package:hopak_frontend/services/admin_service.dart';
import 'package:mocktail/mocktail.dart';

class MockAdminService extends Mock implements AdminService {}

void main() {
  late MockAdminService service;
  late AdminDormsController controller;

  setUp(() {
    service = MockAdminService();
    controller = AdminDormsController(service);
    when(() => service.queue()).thenAnswer(
      (_) async => AdminQueue(
        newDormitories: [
          {'id': 10, 'name': 'New Dorm'},
        ],
        revisions: [
          {'dormitory_id': 11, 'name': 'Edited Dorm'},
        ],
        verifications: [],
      ),
    );
    when(() => service.allDormitories(status: any(named: 'status')))
        .thenAnswer((_) async => []);
  });

  test('1. loadQueue counts new dorms and edit requests', () async {
    expect(await controller.loadQueue(), isTrue);

    expect(controller.newDormitories.length, 1);
    expect(controller.revisions.length, 1);
    expect(controller.awaitingCount, 2);
  });

  test('2. approve calls the backend and reloads the lists', () async {
    when(() => service.approveDormitory(10)).thenAnswer((_) async {});

    expect(await controller.approve(10), isTrue);

    verify(() => service.approveDormitory(10)).called(1);
    verify(() => service.queue()).called(1);
  });

  test('3. suspend and reject without a reason are not sent', () async {
    expect(await controller.suspend(11, ' '), isFalse);
    expect(await controller.reject(10, ''), isFalse);

    verifyNever(() => service.suspendDormitory(any(), any()));
    verifyNever(() => service.rejectDormitory(any(), any()));
    expect(controller.error, isNotNull);
  });

  test('4. suspend sends the trimmed reason', () async {
    when(() => service.suspendDormitory(any(), any())).thenAnswer((_) async {});

    expect(await controller.suspend(11, '  Rule violation  '), isTrue);

    verify(() => service.suspendDormitory(11, 'Rule violation')).called(1);
  });

  test('5. reject with a reason is sent to the backend', () async {
    when(() => service.rejectDormitory(any(), any())).thenAnswer((_) async {});

    expect(await controller.reject(10, 'Blurry photos'), isTrue);

    verify(() => service.rejectDormitory(10, 'Blurry photos')).called(1);
  });

  test('6. restore brings a suspended dorm back', () async {
    when(() => service.restoreDormitory(11)).thenAnswer((_) async {});

    expect(await controller.restore(11), isTrue);

    verify(() => service.restoreDormitory(11)).called(1);
  });
}
