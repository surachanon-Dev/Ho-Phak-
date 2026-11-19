// ผู้รับผิดชอบ: Bank (แอดมิน)
// unit test: AdminDashboardController (ตัวเลขสรุปบนหน้า Dashboard)
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:hopak_frontend/modules/admin/dashboard/controller/admin_dashboard_controller.dart';
import 'package:hopak_frontend/services/admin_service.dart';
import 'package:mocktail/mocktail.dart';

class MockAdminService extends Mock implements AdminService {}

void main() {
  late MockAdminService service;
  late AdminDashboardController controller;

  // ตั้งค่าให้ service ปลอมตอบข้อมูลตามที่กำหนด
  void backendReturns({
    int newDorms = 0,
    int revisions = 0,
    int ownerRequests = 0,
    int pendingReviews = 0,
    int suspendedDorms = 0,
    int suspendedUsers = 0,
  }) {
    List<Map<String, dynamic>> rows(int n) =>
        List.generate(n, (i) => {'id': i + 1});
    when(() => service.queue()).thenAnswer(
      (_) async => AdminQueue(
        newDormitories: rows(newDorms),
        revisions: rows(revisions),
        verifications: rows(ownerRequests),
      ),
    );
    when(() => service.reviews('open'))
        .thenAnswer((_) async => rows(pendingReviews));
    when(() => service.allDormitories(status: 'suspended'))
        .thenAnswer((_) async => rows(suspendedDorms));
    when(() => service.allUsers(status: 'suspended'))
        .thenAnswer((_) async => rows(suspendedUsers));
  }

  setUp(() {
    service = MockAdminService();
    controller = AdminDashboardController(service);
  });

  test('1. load counts every card from the backend data', () async {
    backendReturns(
      newDorms: 2,
      revisions: 1,
      ownerRequests: 1,
      pendingReviews: 1,
      suspendedDorms: 1,
      suspendedUsers: 2,
    );

    expect(await controller.load(), isTrue);

    expect(controller.dormsAwaitingCount, 3); // หอใหม่ 2 + ฉบับแก้ไข 1
    expect(controller.ownerRequestsCount, 1);
    expect(controller.reportedReviewsCount, 1);
    expect(controller.suspendedCount, 3); // หอ 1 + บัญชี 2
    expect(controller.allCaughtUp, isFalse);
  });

  test('2. nothing waiting means all caught up', () async {
    backendReturns();

    await controller.load();

    expect(controller.allCaughtUp, isTrue);
    expect(controller.totalWaiting, 0);
  });

  test('3. backend error keeps the error and stops loading', () async {
    when(() => service.queue()).thenThrow(ApiException(500, 'Server error'));
    when(() => service.reviews(any())).thenAnswer((_) async => []);
    when(() => service.allDormitories(status: any(named: 'status')))
        .thenAnswer((_) async => []);
    when(() => service.allUsers(status: any(named: 'status')))
        .thenAnswer((_) async => []);

    expect(await controller.load(), isFalse);

    expect(controller.error, isA<ApiException>());
    expect(controller.loading, isFalse);
  });
}
