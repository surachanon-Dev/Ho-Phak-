// ผู้รับผิดชอบ: Kren (เจ้าของหอ)
// unit test: MyReviewsController (รีวิวทุกหอ กรองตามหอ และ report)
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:hopak_frontend/model/owner_reviews_bundle.dart';
import 'package:hopak_frontend/model/review.dart';
import 'package:hopak_frontend/model/review_report.dart';
import 'package:hopak_frontend/modules/owner/my_reviews/controller/my_reviews_controller.dart';
import 'package:hopak_frontend/services/dormitory_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/owner_data.dart';

class MockDormitoryService extends Mock implements DormitoryService {}

OwnerReviewEntry entry(String dorm, int id, int rating) => OwnerReviewEntry(
  dorm,
  OwnerReview.fromJson(ownerReviewJson(id: id, rating: rating)),
);

void main() {
  late MockDormitoryService dorms;
  late MyReviewsController controller;

  setUp(() {
    dorms = MockDormitoryService();
    controller = MyReviewsController(dorms);
    when(() => dorms.allReviews()).thenAnswer(
      (_) async => OwnerReviewsBundle(
        [entry('Baan Suan', 1, 5), entry('Baan Rim', 2, 3)],
        ['Baan Suan', 'Baan Rim'],
      ),
    );
    when(() => dorms.reviewReports()).thenAnswer((_) async => {});
  });

  test('1. load shows every review with the average', () async {
    expect(await controller.load(), isTrue);

    expect(controller.visible, hasLength(2));
    expect(controller.dormNames, ['Baan Suan', 'Baan Rim']);
    expect(controller.average, 4.0);
    expect(controller.showFullLoader, isFalse);
  });

  test('2. setFilter shows only that dorm and changes the average', () async {
    await controller.load();

    controller.setFilter('Baan Rim');

    expect(controller.visible.map((e) => e.review.id), [2]);
    expect(controller.average, 3.0);
  });

  test('3. setFilter with an unknown dorm shows everything', () async {
    await controller.load();
    controller.setFilter('Baan Rim');

    controller.setFilter('No such dorm');

    expect(controller.filter, isNull);
    expect(controller.visible, hasLength(2));
  });

  test('4. no reviews gives no average', () async {
    when(() => dorms.allReviews())
        .thenAnswer((_) async => OwnerReviewsBundle([], ['Baan Suan']));

    await controller.load();

    expect(controller.visible, isEmpty);
    expect(controller.average, isNull);
  });

  test('5. load that fails keeps the error', () async {
    when(() => dorms.allReviews()).thenThrow(ApiException(500, 'down'));

    expect(await controller.load(), isFalse);

    expect(controller.error, isA<ApiException>());
  });

  test('6. reports from the backend mark reviews as reported', () async {
    when(() => dorms.reviewReports()).thenAnswer(
      (_) async => {1: const ReviewReport(reviewId: 1, reason: 'Spam')},
    );

    await controller.load();

    expect(controller.isReported(1), isTrue);
    expect(controller.isReported(2), isFalse);
  });

  test('7. report sends the trimmed reason and marks the review', () async {
    when(() => dorms.reportReview(1, 'Spam')).thenAnswer((_) async {});
    await controller.load();
    when(() => dorms.reviewReports()).thenAnswer(
      (_) async => {1: const ReviewReport(reviewId: 1, reason: 'Spam')},
    );

    expect(await controller.report(1, '  Spam  '), isTrue);

    verify(() => dorms.reportReview(1, 'Spam')).called(1);
    expect(controller.isReported(1), isTrue);
  });

  test('8. an empty reason is not sent', () async {
    expect(await controller.report(1, '   '), isFalse);

    verifyNever(() => dorms.reportReview(any(), any()));
    expect(controller.error, isA<ArgumentError>());
  });

  test('9. a reason longer than 300 characters is not sent', () async {
    final tooLong = 'a' * (MyReviewsController.maxReportReasonLength + 1);

    expect(await controller.report(1, tooLong), isFalse);

    verifyNever(() => dorms.reportReview(any(), any()));
  });

  test('10. a reason of exactly 300 characters is accepted', () async {
    final max = 'a' * MyReviewsController.maxReportReasonLength;
    when(() => dorms.reportReview(1, max)).thenAnswer((_) async {});

    expect(await controller.report(1, max), isTrue);
  });

  test('11. a report that fails keeps the error', () async {
    when(() => dorms.reportReview(1, 'Spam'))
        .thenThrow(ApiException(409, 'Already reported'));

    expect(await controller.report(1, 'Spam'), isFalse);

    expect(controller.error, isA<ApiException>());
  });
}
