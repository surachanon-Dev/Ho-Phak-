// ผู้รับผิดชอบ: Big (นักศึกษา)
// unit test: StudentHomeController (หน้าหลักนักศึกษา)
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:hopak_frontend/model/dormitory.dart';
import 'package:hopak_frontend/modules/student/home/controller/student_home_controller.dart';
import 'package:hopak_frontend/services/public_dormitory_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/student_data.dart';

class MockDormService extends Mock implements PublicDormitoryService {}

void main() {
  late MockDormService dorms;
  late StudentHomeController controller;

  setUp(() {
    dorms = MockDormService();
    controller = StudentHomeController(dorms);
  });

  test('1. load keeps the published dorms from the backend', () async {
    when(() => dorms.search()).thenAnswer(
      (_) async => [
        Dormitory.fromJson(dormJson(id: 1, name: 'A')),
        Dormitory.fromJson(dormJson(id: 2, name: 'B')),
      ],
    );

    expect(await controller.load(), isTrue);

    expect(controller.items.map((d) => d.name), ['A', 'B']);
    expect(controller.loading, isFalse);
    expect(controller.isEmpty, isFalse);
  });

  test('2. no dorms means the page is empty', () async {
    when(() => dorms.search()).thenAnswer((_) async => []);

    await controller.load();

    expect(controller.isEmpty, isTrue);
  });

  test('3. backend error keeps the error and the old list', () async {
    when(() => dorms.search())
        .thenAnswer((_) async => [Dormitory.fromJson(dormJson())]);
    await controller.load();
    when(() => dorms.search()).thenThrow(ApiException(500, 'Server error'));

    expect(await controller.refresh(), isFalse);

    expect(controller.error, isA<ApiException>());
    expect(controller.items, hasLength(1));
    expect(controller.isEmpty, isFalse);
  });
}
