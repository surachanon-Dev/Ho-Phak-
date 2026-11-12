import '../core/api_client.dart';
import '../mock/mock_db.dart';
import '../models/activity.dart';
import '../models/dormitory.dart';

class DormFilter {
  final String q;
  final String? zone;
  final int? minPrice;
  final int? maxPrice;
  final List<int> amenityIds;
  final String sort; // newest | price_asc | price_desc | rating | distance

  const DormFilter({
    this.q = '',
    this.zone,
    this.minPrice,
    this.maxPrice,
    this.amenityIds = const [],
    this.sort = 'newest',
  });

  DormFilter copyWith({String? q, String? zone, bool clearZone = false, int? minPrice, int? maxPrice, bool clearPrice = false,
          List<int>? amenityIds, String? sort}) =>
      DormFilter(
        q: q ?? this.q,
        zone: clearZone ? null : (zone ?? this.zone),
        minPrice: clearPrice ? null : (minPrice ?? this.minPrice),
        maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
        amenityIds: amenityIds ?? this.amenityIds,
        sort: sort ?? this.sort,
      );
}

/// Student-facing dorms, reviews and favorites (MOCK)
class DormService {
  final _db = MockDb.instance;
  static const visible = ['published'];

  Future<List<Amenity>> amenities() async => _db.amenities.map(Amenity.fromJson).toList();

  Future<List<Dormitory>> search(DormFilter f) async {
    await MockDb.delay();
    _db.currentUser;
    final q = f.q.trim().toLowerCase();
    final list = _db.dormitories
        .where((d) => visible.contains(d['status']))
        .map(_db.dormJson)
        .where((d) {
          if (f.zone != null && d['zone'] != f.zone) return false;
          if (q.isNotEmpty && !'${d['name']} ${d['address'] ?? ''} ${d['zone']}'.toLowerCase().contains(q)) return false;
          final price = d['price_per_month'] as int;
          if (f.minPrice != null && price < f.minPrice!) return false;
          if (f.maxPrice != null && price > f.maxPrice!) return false;
          final ids = (d['amenities'] as List).map((a) => a['id']).toList();
          if (!f.amenityIds.every(ids.contains)) return false;
          return true;
        })
        .toList();
    int nulls(num? a, num? b, bool desc) {
      if (a == null && b == null) return 0;
      if (a == null) return 1;
      if (b == null) return -1;
      return desc ? b.compareTo(a) : a.compareTo(b);
    }

    list.sort((a, b) => switch (f.sort) {
          'price_asc' => (a['price_per_month'] as int).compareTo(b['price_per_month'] as int),
          'price_desc' => (b['price_per_month'] as int).compareTo(a['price_per_month'] as int),
          'rating' => nulls(a['avg_rating'] as num?, b['avg_rating'] as num?, true),
          'distance' => (a['distance_meters'] as int).compareTo(b['distance_meters'] as int),
          _ => (b['created_at'] as String).compareTo(a['created_at'] as String),
        });
    return list.map(Dormitory.fromJson).toList();
  }

  Future<Dormitory> detail(int id) async {
    await MockDb.delay(200);
    final me = _db.currentUser;
    final d = _db.dormById(id);
    final allowed = d != null && (visible.contains(d['status']) || d['owner_id'] == me['id'] || me['role'] == 'admin');
    if (!allowed) throw ApiException(404, 'ไม่พบหอพัก');
    return Dormitory.fromJson(_db.dormJson(d));
  }

  Future<List<Review>> reviews(int dormId) async {
    final list = _db.publishedReviewsOf(dormId).map(_db.reviewJson).toList()
      ..sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
    return list.map(Review.fromJson).toList();
  }

  /// reviews has UNIQUE(dormitory_id, user_id) → one review per student per dorm
  Future<Review?> myReview(int dormId) async {
    final me = _db.currentUser['id'];
    final r = _db.reviews.where((r) => r['dormitory_id'] == dormId && r['user_id'] == me).firstOrNull;
    return r == null ? null : Review.fromJson(_db.reviewJson(r));
  }

  Future<void> submitReview(int dormId, int rating, String? body) async {
    await MockDb.delay();
    final me = _db.requireRole('student');
    if (rating < 1 || rating > 5) throw ApiException(400, 'คะแนนต้องอยู่ระหว่าง 1–5');
    final d = _db.dormById(dormId);
    if (d == null || !visible.contains(d['status'])) throw ApiException(404, 'ไม่พบหอพัก');
    final existing = _db.reviews.where((r) => r['dormitory_id'] == dormId && r['user_id'] == me['id']).firstOrNull;
    final text = (body ?? '').trim();
    if (existing != null) {
      // no moderation – the edit shows right away
      existing
        ..['rating'] = rating
        ..['body'] = text.isEmpty ? null : text
        ..['status'] = 'published'
        ..['updated_at'] = MockDb.now();
    } else {
      _db.reviews.add({
        'id': _db.nextId('reviews'),
        'dormitory_id': dormId,
        'user_id': me['id'],
        'rating': rating,
        'body': text.isEmpty ? null : text,
        'status': 'published', // shown right away (no admin moderation)
        'moderation_reason': null,
        'moderated_by': null,
        'moderated_at': null,
        'created_at': MockDb.now(),
        'updated_at': MockDb.now(),
      });
    }
  }

  Future<List<Review>> myReviews() async {
    await MockDb.delay(200);
    final me = _db.currentUser['id'];
    return _db.reviews.where((r) => r['user_id'] == me).map(_db.reviewJson).map(Review.fromJson).toList();
  }

  // ----- favorites table -----
  Future<Set<int>> favoriteIds() async {
    final me = _db.currentUser['id'];
    return _db.favorites.where((f) => f['user_id'] == me).map((f) => f['dormitory_id'] as int).toSet();
  }

  Future<List<Dormitory>> favorites() async {
    await MockDb.delay(200);
    final ids = await favoriteIds();
    return _db.dormitories
        .where((d) => ids.contains(d['id']) && visible.contains(d['status']))
        .map((d) => Dormitory.fromJson(_db.dormJson(d)))
        .toList();
  }

  Future<bool> toggleFavorite(int dormId) async {
    final me = _db.currentUser['id'];
    final i = _db.favorites.indexWhere((f) => f['user_id'] == me && f['dormitory_id'] == dormId);
    if (i >= 0) {
      _db.favorites.removeAt(i);
      return false;
    }
    _db.favorites.add({'user_id': me, 'dormitory_id': dormId, 'created_at': MockDb.now()});
    return true;
  }
}
