// ผู้รับผิดชอบ: Bank (แอดมิน)
// unit test: AdminOwnerRequestsController (อนุมัติ / ปฏิเสธคำขอเป็นเจ้าของหอ)
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/modules/admin/owner_requests/controller/admin_owner_requests_controller.dart';
import 'package:hopak_frontend/services/admin_service.dart';
import 'package:mocktail/mocktail.dart';

class MockAdminService extends Mock implements AdminService {}

void main() {
  late MockAdminService service;
  late AdminOwnerRequestsController controller;

  setUp(() {
    service = MockAdminService();
    controller = AdminOwnerRequestsController(service);
    when(() => service.verifications('pending')).thenAnswer(
      (_) async => [
        {'id': 1},
        {'id': 2},
      ],
    );
    when(() => service.verifications('approved')).thenAnswer(
      (_) async => [
        {'id': 3},
      ],
    );
    when(() => service.verifications('rejected')).thenAnswer((_) async => []);
  });

  test(
    '1. load splits the requests into Pending / Approved / Rejected',
    () async {
      expect(await controller.load(), isTrue);

      expect(controller.pendingCount, 2);
      expect(controller.approved.length, 1);
      expect(controller.rejected, isEmpty);
    },
  );

  test('2. approve sends the request and reloads the list', () async {
    when(() => service.approveVerification(1)).thenAnswer((_) async {});

    expect(await controller.approve(1), isTrue);

    verify(() => service.approveVerification(1)).called(1);
    verify(() => service.verifications('pending')).called(1);
  });

  test('3. reject needs a reason and sends it trimmed', () async {
    when(() => service.rejectVerification(any(), any()))
        .thenAnswer((_) async {});

    // ไม่มีเหตุผล: ไม่ส่งไป backend
    expect(await controller.reject(1, '   '), isFalse);
    verifyNever(() => service.rejectVerification(any(), any()));

    // มีเหตุผล: ส่งเหตุผลที่ตัดช่องว่างแล้ว
    expect(await controller.reject(1, '  Blurry document  '), isTrue);
    verify(() => service.rejectVerification(1, 'Blurry document')).called(1);
  });
}
