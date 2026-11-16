import '../models/dormitory.dart';
import '../models/review.dart';
import 'api_client.dart';

/// endpoint สาธารณะของนักศึกษา (ไม่ต้อง login ก็เรียกได้)
class PublicDormitoryService {
  PublicDormitoryService(this._api);

  final ApiClient _api;

  /// GET /api/dormitories?zone&minPrice&maxPrice&hasRooms=1&q&sort
  /// sort: price_asc | price_desc | newest
  Future<List<Dormitory>> search({
    String? zone,
    int? minPrice,
    int? maxPrice,
    bool roomsOnly = false,
    String? query,
    String sort = 'newest',
  }) async {
    final params = <String, String>{
      if (zone != null) 'zone': zone,
      if (minPrice != null) 'minPrice': '$minPrice',
      if (maxPrice != null) 'maxPrice': '$maxPrice',
      if (roomsOnly) 'hasRooms': '1',
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      'sort': sort,
    };
    final qs = Uri(queryParameters: params).query;
    final data = await _api.get(
      '/api/dormitories${qs.isEmpty ? '' : '?$qs'}',
    ) as Map<String, dynamic>;
    return (data['dormitories'] as List)
        .map((e) => Dormitory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/dormitories/:id → { dormitory: {..., images, amenities, rating_avg, review_count} }
  Future<Dormitory> detail(int id) async {
    final data = await _api.get('/api/dormitories/$id') as Map<String, dynamic>;
    return Dormitory.fromJson(data['dormitory'] as Map<String, dynamic>);
  }

  /// GET /api/dormitories/:id/reviews → { reviews, summary }
  Future<List<OwnerReview>> reviews(int id) async {
    final data =
        await _api.get('/api/dormitories/$id/reviews') as Map<String, dynamic>;
    return (data['reviews'] as List)
        .map((e) => OwnerReview.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/dormitories/:id/reviews { rating 1-5, body? } → รอแอดมินตรวจ (409 ถ้าเคยรีวิวแล้ว)
  Future<void> addReview(int id, int rating, String? body) => _api.post(
    '/api/dormitories/$id/reviews',
    {'rating': rating, if (body != null && body.isNotEmpty) 'body': body},
  );
}
