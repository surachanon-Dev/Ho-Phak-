// ผู้รับผิดชอบ: Plub (เจ้าของหอ)
// unit test: OwnerDashboardController และ DormitorySummary (สรุปหอบนหน้า My Dorms)
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:hopak_frontend/model/dormitory.dart';
import 'package:hopak_frontend/model/dormitory_summary.dart';
import 'package:hopak_frontend/modules/owner/dashboard/controller/owner_dashboard_controller.dart';
import 'package:hopak_frontend/services/dormitory_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/owner_data.dart';

class MockDormitoryService extends Mock implements DormitoryService {}

Dormitory dorm(Map<String, dynamic> json) => Dormitory.fromJson(json);

void main() {
  late MockDormitoryService dorms;
  late OwnerDashboardController controller;

  setUp(() {
    dorms = MockDormitoryService();
    controller = OwnerDashboardController(dorms);
  });

  test('1. starts loading with a full-page loader and no dorms', () {
    expect(controller.loading, isTrue);
    expect(controller.showFullLoader, isTrue);
    expect(controller.items, isEmpty);
  });

  test('2. load keeps the dorms and stops the loader', () async {
    when(() => dorms.list()).thenAnswer(
      (_) async => [dorm(ownerDormJson(id: 1)), dorm(ownerDormJson(id: 2))],
    );

    expect(await controller.load(), isTrue);

    expect(controller.items.map((d) => d.id), [1, 2]);
    expect(controller.loading, isFalse);
    expect(controller.error, isNull);
  });

  test('3. load that fails keeps the error and returns false', () async {
    when(() => dorms.list()).thenThrow(ApiException(500, 'down'));

    expect(await controller.load(), isFalse);

    expect(controller.error, isA<ApiException>());
    expect(controller.loading, isFalse);
  });

  test('4. a failed reload keeps the dorms that were already shown', () async {
    when(() => dorms.list())
        .thenAnswer((_) async => [dorm(ownerDormJson(id: 1))]);
    await controller.load();
    when(() => dorms.list()).thenThrow(ApiException(0, 'offline'));

    expect(await controller.load(), isFalse);

    expect(controller.items, hasLength(1));
    expect(controller.showFullLoader, isFalse);
  });

  test('5. summary adds up rooms and counts published dorms', () {
    final summary = DormitorySummary.of([
      dorm(ownerDormJson(id: 1, available: 4)),
      dorm(ownerDormJson(id: 2, available: 3)),
      dorm(ownerDormJson(id: 3, status: 'hidden', available: 5)),
    ]);

    expect(summary.totalAvailable, 12);
    expect(summary.published, 2);
  });

  test('6. summary flags pending, rejected and suspended dorms', () {
    final summary = DormitorySummary.of([
      dorm(ownerDormJson(id: 1, status: 'pending')),
      dorm(ownerDormJson(id: 2, status: 'pending')),
      dorm(ownerDormJson(id: 3, status: 'rejected')),
      dorm(ownerDormJson(id: 4, status: 'suspended')),
      dorm(ownerDormJson(id: 5, status: 'published')),
    ]);

    expect(summary.attention, {'pending': 2, 'rejected': 1, 'suspended': 1});
    expect(summary.attentionTotal, 4);
  });
}
