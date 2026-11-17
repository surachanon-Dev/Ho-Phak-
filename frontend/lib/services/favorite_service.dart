import '../models/favorite.dart';
import 'api_client.dart';

class FavoriteService {
  FavoriteService(this._api);

  final ApiClient _api;

  /// GET /api/favorites → { favorites: [...] }
  Future<List<Favorite>> list() async {
    final data = await _api.get('/api/favorites') as Map<String, dynamic>;
    return (data['favorites'] as List)
        .map((e) => Favorite.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/favorites/:dormitoryId (เฉพาะหอที่ published)
  Future<void> add(int dormitoryId) =>
      _api.post('/api/favorites/$dormitoryId', const {});

  /// DELETE /api/favorites/:dormitoryId
  Future<void> remove(int dormitoryId) =>
      _api.delete('/api/favorites/$dormitoryId');
}
