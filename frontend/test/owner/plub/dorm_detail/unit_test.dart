// ผู้รับผิดชอบ: Plub (เจ้าของหอ)
// unit test: OwnerDormDetailController (รายละเอียดหอ สลับการแสดง ลบหอ)
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:hopak_frontend/model/amenity.dart';
import 'package:hopak_frontend/model/dormitory.dart';
import 'package:hopak_frontend/model/review.dart';
import 'package:hopak_frontend/modules/owner/dorm_detail/controller/owner_dorm_detail_controller.dart';
import 'package:hopak_frontend/modules/owner/dorm_detail/model/dorm_detail_extras.dart';
import 'package:hopak_frontend/services/dormitory_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/owner_data.dart';

class MockDormitoryService extends Mock implements DormitoryService {}

void main() {
  late MockDormitoryService dorms;
  late OwnerDormDetailController controller;

  setUp(() {
    dorms = MockDormitoryService();
    controller = OwnerDormDetailController(dormitoryId: 1, dorms: dorms);
    when(() => dorms.get(1))
        .thenAnswer((_) async => Dormitory.fromJson(ownerDormJson(id: 1)));
    when(() => dorms.reviews(1)).thenAnswer(
      (_) async => [
        OwnerReview.fromJson(ownerReviewJson(id: 1, rating: 5)),
        OwnerReview.fromJson(ownerReviewJson(id: 2, rating: 2)),
      ],
    );
    when(() => dorms.loadDetailExtras(any())).thenAnswer(
      (_) async => DormDetailExtras(amenities: [Amenity(1, 'Wi-Fi')]),
    );
  });

  setUpAll(() {
    registerFallbackValue(Dormitory.fromJson(ownerDormJson()));
  });

  test('1. load fills the dorm, reviews and amenities', () async {
    expect(await controller.load(), isTrue);

    expect(controller.dorm!.name, 'Baan Suan');
    expect(controller.reviews, hasLength(2));
    expect(controller.amenities.single.name, 'Wi-Fi');
    expect(controller.loading, isFalse);
  });

  test('2. averageRating and latestReview come from the reviews', () async {
    await controller.load();

    expect(controller.averageRating, 3.5);
    expect(controller.latestReview!.id, 1);
  });

  test('3. a dorm without reviews has no average', () async {
    when(() => dorms.reviews(1)).thenAnswer((_) async => []);
    await controller.load();

    expect(controller.averageRating, isNull);
    expect(controller.latestReview, isNull);
  });

  test('4. load that fails keeps the error', () async {
    when(() => dorms.get(1)).thenThrow(ApiException(404, 'not found'));

    expect(await controller.load(), isFalse);

    expect(controller.error, isA<ApiException>());
    expect(controller.dorm, isNull);
  });

  test('5. toggleVisibility calls the backend and marks changed', () async {
    when(() => dorms.toggleVisibility(1)).thenAnswer((_) async => 'hidden');
    await controller.load();

    expect(await controller.toggleVisibility(), isTrue);

    verify(() => dorms.toggleVisibility(1)).called(1);
    verify(() => dorms.get(1)).called(2); // โหลดครั้งแรก + โหลดใหม่หลังสลับ
    expect(controller.changed, isTrue);
    expect(controller.busy, isFalse);
  });

  test('6. toggleVisibility that fails keeps the error', () async {
    when(() => dorms.toggleVisibility(1))
        .thenThrow(ApiException(409, 'Not allowed'));
    await controller.load();

    expect(await controller.toggleVisibility(), isFalse);

    expect(controller.error, isA<ApiException>());
    expect(controller.changed, isFalse);
    expect(controller.busy, isFalse);
  });

  test('7. delete removes the dorm and marks changed', () async {
    when(() => dorms.delete(1)).thenAnswer((_) async {});
    await controller.load();

    expect(await controller.delete(), isTrue);

    verify(() => dorms.delete(1)).called(1);
    expect(controller.changed, isTrue);
  });

  test('8. delete before the dorm is loaded does nothing', () async {
    expect(await controller.delete(), isFalse);

    verifyNever(() => dorms.delete(any()));
  });

  test('9. reloadAfterEdit marks changed and loads again', () async {
    await controller.load();

    expect(await controller.reloadAfterEdit(), isTrue);

    expect(controller.changed, isTrue);
    verify(() => dorms.get(1)).called(2);
  });
}
