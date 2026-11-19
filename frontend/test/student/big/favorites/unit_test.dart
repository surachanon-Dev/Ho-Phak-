// ผู้รับผิดชอบ: Big (นักศึกษา)
// unit test: FavoritesController (รายการโปรด)
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:hopak_frontend/model/favorite.dart';
import 'package:hopak_frontend/modules/student/favorites/controller/favorites_controller.dart';
import 'package:hopak_frontend/services/favorite_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/student_data.dart';

class MockFavoriteService extends Mock implements FavoriteService {}

void main() {
  late MockFavoriteService favorites;
  late FavoritesController controller;

  setUp(() {
    favorites = MockFavoriteService();
    controller = FavoritesController(favorites);
    when(() => favorites.list()).thenAnswer(
      (_) async => [
        Favorite.fromJson(favoriteJson(id: 1, name: 'Open Dorm')),
        Favorite.fromJson(
          favoriteJson(id: 2, name: 'Closed Dorm', status: 'suspended'),
        ),
      ],
    );
  });

  test(
    '1. load keeps every saved dorm and counts the available ones',
    () async {
      expect(await controller.load(), isTrue);

      expect(controller.items, hasLength(2));
      expect(controller.availableCount, 1);
      expect(controller.items[1].isAvailable, isFalse);
    },
  );

  test('2. remove deletes the dorm from the list right away', () async {
    when(() => favorites.remove(1)).thenAnswer((_) async {});
    await controller.load();

    expect(await controller.remove(1), isTrue);

    verify(() => favorites.remove(1)).called(1);
    expect(controller.items.map((f) => f.id), [2]);
  });

  test('3. remove that fails keeps the list and the error', () async {
    when(() => favorites.remove(1)).thenThrow(ApiException(500, 'down'));
    await controller.load();

    expect(await controller.remove(1), isFalse);

    expect(controller.items, hasLength(2));
    expect(controller.error, isA<ApiException>());
  });
}
