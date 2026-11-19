// ผู้รับผิดชอบ: Big (นักศึกษา)
// unit test: MyReviewsController (รีวิวของฉัน แก้ไข และลบ)
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/model/review.dart';
import 'package:hopak_frontend/modules/student/my_reviews/controller/my_reviews_controller.dart';
import 'package:hopak_frontend/services/public_dormitory_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/student_data.dart';

class MockDormService extends Mock implements PublicDormitoryService {}

void main() {
  late MockDormService dorms;
  late MyReviewsController controller;

  setUp(() {
    dorms = MockDormService();
    controller = MyReviewsController(dorms);
    when(() => dorms.myReviews()).thenAnswer(
      (_) async => [
        MyReview.fromJson(myReviewJson(id: 1)),
        MyReview.fromJson(
          myReviewJson(id: 2, status: 'hidden', reason: 'Spam'),
        ),
      ],
    );
  });

  test('1. load shows every review with the reason when hidden', () async {
    expect(await controller.load(), isTrue);

    expect(controller.items, hasLength(2));
    expect(controller.items[1].isHidden, isTrue);
    expect(controller.items[1].moderationReason, 'Spam');
  });

  test('2. update with a rating outside 1–5 is not sent', () async {
    expect(await controller.update(1, rating: 6), isFalse);

    verifyNever(() => dorms.updateReview(any(), any(), any()));
    expect(controller.error, isNotNull);
  });

  test('3. update sends the trimmed comment and reloads', () async {
    when(() => dorms.updateReview(any(), any(), any()))
        .thenAnswer((_) async {});

    expect(await controller.update(1, rating: 5, body: '  Great  '), isTrue);

    verify(() => dorms.updateReview(1, 5, 'Great')).called(1);
    verify(() => dorms.myReviews()).called(1);
  });

  test('4. remove takes the review off the list', () async {
    when(() => dorms.deleteReview(1)).thenAnswer((_) async {});
    await controller.load();

    expect(await controller.remove(1), isTrue);

    verify(() => dorms.deleteReview(1)).called(1);
    expect(controller.items.map((r) => r.id), [2]);
  });
}
