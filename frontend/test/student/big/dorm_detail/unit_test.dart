// ผู้รับผิดชอบ: Big (นักศึกษา)
// unit test: DormDetailController (รายละเอียดหอ รายการโปรด แชท และรีวิว)
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:hopak_frontend/model/dormitory.dart';
import 'package:hopak_frontend/model/favorite.dart';
import 'package:hopak_frontend/model/review.dart';
import 'package:hopak_frontend/modules/student/dorm_detail/controller/dorm_detail_controller.dart';
import 'package:hopak_frontend/services/chat_service.dart';
import 'package:hopak_frontend/services/favorite_service.dart';
import 'package:hopak_frontend/services/public_dormitory_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/student_data.dart';

class MockDormService extends Mock implements PublicDormitoryService {}

class MockFavoriteService extends Mock implements FavoriteService {}

class MockChatService extends Mock implements ChatService {}

void main() {
  late MockDormService dorms;
  late MockFavoriteService favorites;
  late MockChatService chats;
  late DormDetailController controller;

  // backend ปลอม: หอ 1 มีรีวิว 1 รายการ และ [saved] บอกว่าอยู่ในรายการโปรดไหม
  void backendHas({bool saved = false}) {
    when(() => dorms.detail(1)).thenAnswer(
      (_) async => Dormitory.fromJson(dormJson(rating: 4.5, reviewCount: 1)),
    );
    when(() => dorms.reviews(1)).thenAnswer(
      (_) async => [
        OwnerReview.fromJson({
          'id': 5,
          'rating': 5,
          'body': 'Great',
          'created_at': '2026-11-10',
        }),
      ],
    );
    when(
      () => favorites.list(),
    ).thenAnswer((_) async => saved ? [Favorite.fromJson(favoriteJson())] : []);
  }

  setUp(() {
    dorms = MockDormService();
    favorites = MockFavoriteService();
    chats = MockChatService();
    controller = DormDetailController(
      dormitoryId: 1,
      myUserId: 9,
      dorms: dorms,
      favorites: favorites,
      chats: chats,
    );
  });

  test(
    '1. load combines the dorm, its reviews and the favorite status',
    () async {
      backendHas(saved: true);

      expect(await controller.load(), isTrue);

      expect(controller.dorm?.name, 'Sunrise Dorm');
      expect(controller.reviews, hasLength(1));
      expect(controller.ratingAvg, 4.5);
      expect(controller.isFavorite, isTrue);
    },
  );

  test('2. toggleFavorite saves a dorm that is not saved yet', () async {
    backendHas();
    when(() => favorites.add(1)).thenAnswer((_) async {});
    await controller.load();

    expect(await controller.toggleFavorite(), isTrue);

    verify(() => favorites.add(1)).called(1);
    expect(controller.isFavorite, isTrue);
  });

  test('3. toggleFavorite that fails keeps the old status', () async {
    backendHas(saved: true);
    when(() => favorites.remove(1)).thenThrow(ApiException(500, 'down'));
    await controller.load();

    expect(await controller.toggleFavorite(), isFalse);

    expect(controller.isFavorite, isTrue);
    expect(controller.error, isA<ApiException>());
  });

  test('4. openChat returns the conversation id', () async {
    when(() => chats.open(1)).thenAnswer((_) async => 42);

    expect(await controller.openChat(), 42);
    verify(() => chats.open(1)).called(1);
  });

  test('5. submitReview checks the rating and trims the comment', () async {
    when(() => dorms.addReview(any(), any(), any())).thenAnswer((_) async {});

    // คะแนนนอก 1–5: ไม่ส่งไป backend
    expect(await controller.submitReview(rating: 0), isFalse);
    verifyNever(() => dorms.addReview(any(), any(), any()));

    expect(
      await controller.submitReview(rating: 4, body: '  Clean room  '),
      isTrue,
    );
    verify(() => dorms.addReview(1, 4, 'Clean room')).called(1);
  });

  test(
    '6. submitReview reloads the reviews because they go live at once',
    () async {
      backendHas();
      when(() => dorms.addReview(any(), any(), any())).thenAnswer((_) async {});

      expect(await controller.submitReview(rating: 5, body: 'Nice'), isTrue);

      verify(() => dorms.reviews(1)).called(1);
      verify(() => dorms.detail(1)).called(1);
      expect(controller.reviews, hasLength(1));
      expect(controller.error, isNull);
    },
  );
}
