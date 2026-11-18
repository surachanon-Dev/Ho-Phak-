// ผู้รับผิดชอบ: Big (นักศึกษา)
// ไฟล์นี้เป็นเทสต์ unit ของ controller ที่ระบุในชื่อ group
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/student/dorm_detail/dorm_detail_controller.dart';
import 'package:hopak_frontend/features/student/search/dorm_search_controller.dart';
import 'package:hopak_frontend/features/student/favorites/favorites_controller.dart';
import 'package:hopak_frontend/features/student/home/student_home_controller.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:hopak_frontend/features/chat/services/chat_service.dart';
import 'package:hopak_frontend/features/student/services/favorite_service.dart';
import 'package:hopak_frontend/features/student/services/public_dormitory_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

typedef Handler = http.Response Function(http.Request req);

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> _dorm({
  int id = 1,
  String name = 'หอ A',
  String zone = 'หน้ามอ',
  String status = 'published',
  int price = 3500,
  int available = 4,
}) => {
  'id': id,
  'name': name,
  'zone': zone,
  'latitude': '19.88010000',
  'longitude': '99.83230000',
  'price_per_month': price,
  'total_rooms': 10,
  'available_rooms': available,
  'status': status,
  'water_rate': '18.00',
  'water_billing_type': 'per_unit',
  'electricity_rate': null,
  'electricity_billing_type': null,
  'description': 'รายละเอียด',
  'address': 'ที่อยู่',
  'contact_phone': '0855500002',
  'rating_avg': '4.5',
  'review_count': 2,
  'amenity_ids': [1, 2],
  'images': <Map<String, dynamic>>[],
};

Map<String, dynamic> _fav({
  int id = 1,
  String status = 'published',
}) => {
  'id': id,
  'name': 'หอ $id',
  'zone': 'หน้ามอ',
  'price_per_month': 3000,
  'status': status,
  'saved_at': '2026-11-17T01:00:00.000Z',
};

/// สร้าง service จริงบน ApiClient ที่ใช้ MockClient แทนเครือข่าย
class Harness {
  Harness(this.handler) {
    api = ApiClient(
      tokenProvider: () => 'test-token',
      client: MockClient((req) async {
        requests.add(req);
        return handler(req);
      }),
    );
    publicDorms = PublicDormitoryService(api);
    favorites = FavoriteService(api);
    chats = ChatService(api);
  }

  final Handler handler;
  final List<http.Request> requests = [];
  late final ApiClient api;
  late final PublicDormitoryService publicDorms;
  late final FavoriteService favorites;
  late final ChatService chats;
}

void main() {
  group('parsePriceInput', () {
    test('คืน null สำหรับค่าว่าง ค่าที่ไม่ใช่ตัวเลข และค่าติดลบ', () {
      expect(parsePriceInput(null), isNull);
      expect(parsePriceInput(''), isNull);
      expect(parsePriceInput('   '), isNull);
      expect(parsePriceInput('abc'), isNull);
      expect(parsePriceInput('-100'), isNull);
      expect(parsePriceInput('3.5'), isNull);
    });

    test('แปลงตัวเลขที่มีช่องว่างรอบ ๆ ได้', () {
      expect(parsePriceInput('3500'), 3500);
      expect(parsePriceInput('  0 '), 0);
    });
  });

  group('SearchFilters', () {
    test('ค่าเริ่มต้นไม่มีข้อผิดพลาดช่วงราคา', () {
      expect(const SearchFilters().priceRangeError, isNull);
    });

    test('ราคาต่ำสุดมากกว่าสูงสุดให้ error', () {
      const f = SearchFilters(minPriceText: '5000', maxPriceText: '3000');
      expect(f.priceRangeError, isNotNull);
    });

    test('ช่วงราคาเท่ากันยังถูกต้อง', () {
      const f = SearchFilters(minPriceText: '3000', maxPriceText: '3000');
      expect(f.priceRangeError, isNull);
    });

    test('copyWith clearZone ล้างโซนได้', () {
      final f = const SearchFilters(zone: 'หน้ามอ').copyWith(clearZone: true);
      expect(f.zone, isNull);
    });
  });

  group('StudentHomeController', () {
    test('load สำเร็จ เก็บรายการและแจ้งผู้ฟังตามลำดับ', () async {
      final h = Harness((req) => _json({
        'dormitories': [_dorm(id: 1), _dorm(id: 2, name: 'หอ B')],
      }));
      final c = StudentHomeController(h.publicDorms);
      expect(c.loading, isTrue, reason: 'เริ่มต้นด้วยสถานะกำลังโหลด');

      var notifications = 0;
      c.addListener(() => notifications++);
      final ok = await c.load();

      expect(ok, isTrue);
      expect(c.items.map((d) => d.id), [1, 2]);
      expect(c.loading, isFalse);
      expect(c.error, isNull);
      expect(c.isEmpty, isFalse);
      expect(notifications, 2, reason: 'แจ้งตอนเริ่มโหลดและตอนจบ');
      expect(h.requests.single.url.path, '/api/dormitories');
    });

    test('ตอบรายการว่างแล้ว isEmpty เป็น true', () async {
      final h = Harness((req) => _json({'dormitories': []}));
      final c = StudentHomeController(h.publicDorms);
      await c.load();
      expect(c.isEmpty, isTrue);
    });

    test('server error เก็บ error และไม่ทิ้งรายการเดิม', () async {
      var calls = 0;
      final h = Harness((req) {
        calls++;
        if (calls == 1) return _json({'dormitories': [_dorm()]});
        return _json({'message': 'DB error'}, 500);
      });
      final c = StudentHomeController(h.publicDorms);
      await c.load();
      final ok = await c.refresh();

      expect(ok, isFalse);
      expect(c.error, isA<ApiException>());
      expect(c.items.length, 1, reason: 'ยังแสดงรายการเดิมได้');
      expect(c.isEmpty, isFalse);
    });

    test('showFullLoader เป็น true เฉพาะตอนโหลดครั้งแรกที่ยังไม่มีข้อมูล', () async {
      final h = Harness((req) => _json({'dormitories': [_dorm()]}));
      final c = StudentHomeController(h.publicDorms);
      expect(c.showFullLoader, isTrue);
      await c.load();
      expect(c.showFullLoader, isFalse);
    });
  });

  group('DormSearchController', () {
    test('search ส่ง query string ตามตัวกรองทั้งหมด', () async {
      final h = Harness((req) => _json({'dormitories': [_dorm()]}));
      final c = DormSearchController(h.publicDorms);
      c.setQuery('  หอ  ');
      c.setZone('หน้ามอ');
      c.setMinPrice('3000');
      c.setMaxPrice('4000');
      c.setRoomsOnly(true);
      c.setSort('price_asc');

      final ok = await c.search();

      expect(ok, isTrue);
      final q = h.requests.single.url.queryParameters;
      expect(q['zone'], 'หน้ามอ');
      expect(q['q'], 'หอ');
      expect(q['minPrice'], '3000');
      expect(q['maxPrice'], '4000');
      expect(q['hasRooms'], '1');
      expect(q['sort'], 'price_asc');
      expect(c.items.length, 1);
    });

    test('ค่าว่างไม่ถูกส่งไปเป็น query', () async {
      final h = Harness((req) => _json({'dormitories': []}));
      final c = DormSearchController(h.publicDorms);
      await c.search();
      final q = h.requests.single.url.queryParameters;
      expect(q.containsKey('zone'), isFalse);
      expect(q.containsKey('q'), isFalse);
      expect(q.containsKey('minPrice'), isFalse);
      expect(q.containsKey('hasRooms'), isFalse);
      expect(q['sort'], 'newest');
    });

    test('ช่วงราคาผิด ไม่ยิง request และตั้ง filterError', () async {
      final h = Harness((req) => _json({'dormitories': []}));
      final c = DormSearchController(h.publicDorms);
      c.setMinPrice('5000');
      c.setMaxPrice('3000');

      final ok = await c.search();

      expect(ok, isFalse);
      expect(h.requests, isEmpty);
      expect(c.filterError, isNotNull);
    });

    test('เมื่อแก้ช่วงราคาให้ถูก filterError หายไปในการค้นหาครั้งถัดไป', () async {
      final h = Harness((req) => _json({'dormitories': []}));
      final c = DormSearchController(h.publicDorms);
      c.setMinPrice('5000');
      c.setMaxPrice('3000');
      await c.search();
      c.setMaxPrice('6000');
      await c.search();
      expect(c.filterError, isNull);
      expect(h.requests.length, 1);
    });

    test('setZone(null) กลับเป็นทุกโซน', () {
      final h = Harness((req) => _json({'dormitories': []}));
      final c = DormSearchController(h.publicDorms);
      c.setZone('หลังมอ');
      expect(c.filters.zone, 'หลังมอ');
      c.setZone(null);
      expect(c.filters.zone, isNull);
    });

    test('setSort รับเฉพาะค่าที่รู้จัก', () {
      final h = Harness((req) => _json({'dormitories': []}));
      final c = DormSearchController(h.publicDorms);
      c.setSort('hack');
      expect(c.filters.sort, 'newest');
      c.setSort('price_desc');
      expect(c.filters.sort, 'price_desc');
    });

    test('hasActiveFilters เปลี่ยนตามการตั้งค่า และ reset ล้างทั้งหมด', () async {
      final h = Harness((req) => _json({'dormitories': []}));
      final c = DormSearchController(h.publicDorms);
      expect(c.hasActiveFilters, isFalse);

      c.setRoomsOnly(true);
      expect(c.hasActiveFilters, isTrue);

      await c.reset();
      expect(c.hasActiveFilters, isFalse);
      expect(h.requests.last.url.queryParameters.containsKey('hasRooms'), isFalse);
    });

    test('server error เก็บ error และคืน false', () async {
      final h = Harness((req) => _json({'message': 'DB error'}, 500));
      final c = DormSearchController(h.publicDorms);
      final ok = await c.search();
      expect(ok, isFalse);
      expect(c.error, isA<ApiException>());
      expect(c.loading, isFalse);
    });

    test('sortLabels มีครบทั้ง 3 แบบที่ backend รองรับ', () {
      expect(DormSearchController.sortLabels.keys.toSet(),
          {'newest', 'price_asc', 'price_desc'});
    });
  });

  group('FavoritesController', () {
    test('load แยกหอที่พร้อมให้บริการและไม่พร้อมได้', () async {
      final h = Harness((req) => _json({
        'favorites': [
          _fav(id: 1),
          _fav(id: 2, status: 'hidden'),
          _fav(id: 3, status: 'suspended'),
        ],
      }));
      final c = FavoritesController(h.favorites);
      await c.load();
      expect(c.items.length, 3);
      expect(c.availableCount, 1);
      expect(c.showFullLoader, isFalse);
    });

    test('remove สำเร็จ ลบออกจากรายการและเรียก DELETE ถูกเส้นทาง', () async {
      final h = Harness((req) {
        if (req.method == 'DELETE') return _json({'message': 'ok'});
        return _json({'favorites': [_fav(id: 1), _fav(id: 2)]});
      });
      final c = FavoritesController(h.favorites);
      await c.load();

      final ok = await c.remove(2);

      expect(ok, isTrue);
      expect(c.items.map((f) => f.id), [1]);
      final del = h.requests.last;
      expect(del.method, 'DELETE');
      expect(del.url.path, '/api/favorites/2');
    });

    test('remove ไม่สำเร็จ รายการเดิมยังอยู่และมี error', () async {
      final h = Harness((req) {
        if (req.method == 'DELETE') return _json({'message': 'ไม่พบรายการโปรด'}, 404);
        return _json({'favorites': [_fav(id: 1)]});
      });
      final c = FavoritesController(h.favorites);
      await c.load();

      final ok = await c.remove(1);

      expect(ok, isFalse);
      expect(c.items.length, 1);
      expect(c.error, isA<ApiException>());
    });

    test('load ล้มเหลวคืน false และ loading กลับเป็น false', () async {
      final h = Harness((req) => _json({'message': 'x'}, 500));
      final c = FavoritesController(h.favorites);
      final ok = await c.load();
      expect(ok, isFalse);
      expect(c.loading, isFalse);
      expect(c.error, isNotNull);
    });
  });

  group('DormDetailController', () {
    DormDetailController build(Harness h, {int id = 7}) => DormDetailController(
      dormitoryId: id,
      myUserId: 20,
      dorms: h.publicDorms,
      favorites: h.favorites,
      chats: h.chats,
    );

    Handler standardHandler({List<Map<String, dynamic>> favorites = const []}) {
      return (req) {
        final p = req.url.path;
        if (req.method == 'GET' && p == '/api/dormitories/7') {
          return _json({'dormitory': _dorm(id: 7)});
        }
        if (req.method == 'GET' && p == '/api/dormitories/7/reviews') {
          return _json({
            'reviews': [
              {'id': 1, 'rating': 5, 'body': 'ดีมาก', 'created_at': '2026-11-01'},
            ],
            'summary': {'review_count': 1, 'rating_avg': '5.00'},
          });
        }
        if (req.method == 'GET' && p == '/api/favorites') {
          return _json({'favorites': favorites});
        }
        if (req.method == 'POST' && p == '/api/favorites/7') {
          return _json({'message': 'added'}, 201);
        }
        if (req.method == 'DELETE' && p == '/api/favorites/7') {
          return _json({'message': 'removed'});
        }
        if (req.method == 'POST' && p == '/api/conversations') {
          return _json({'id': 99, 'message': 'เปิดแชทแล้ว'}, 201);
        }
        if (req.method == 'POST' && p == '/api/dormitories/7/reviews') {
          return _json({'message': 'ส่งรีวิวแล้ว'}, 201);
        }
        return _json({'message': 'not mocked: ${req.method} $p'}, 404);
      };
    }

    test('load รวมข้อมูลหอ รีวิว และสถานะรายการโปรด', () async {
      final h = Harness(standardHandler(favorites: [_fav(id: 7)]));
      final c = build(h);

      final ok = await c.load();

      expect(ok, isTrue);
      expect(c.dorm?.name, 'หอ A');
      expect(c.reviews.single.rating, 5);
      expect(c.isFavorite, isTrue);
      expect(c.ratingAvg, 4.5);
      expect(c.loading, isFalse);
    });

    test('ถ้าโหลดรายการโปรดไม่ได้ load ล้มเหลวทั้งหมด', () async {
      final base = standardHandler();
      final h = Harness((req) {
        if (req.url.path == '/api/favorites') return _json({'message': 'x'}, 500);
        return base(req);
      });
      final c = build(h);
      final ok = await c.load();
      expect(ok, isFalse);
      expect(c.error, isNotNull);
      expect(c.loading, isFalse);
    });

    test('toggleFavorite เพิ่มเมื่อยังไม่ได้บันทึก', () async {
      final h = Harness(standardHandler());
      final c = build(h);
      await c.load();
      expect(c.isFavorite, isFalse);

      final ok = await c.toggleFavorite();

      expect(ok, isTrue);
      expect(c.isFavorite, isTrue);
      expect(h.requests.where((r) => r.method == 'POST').single.url.path,
          '/api/favorites/7');
      expect(c.busy, isFalse);
    });

    test('toggleFavorite ลบเมื่อบันทึกไว้แล้ว', () async {
      final h = Harness(standardHandler(favorites: [_fav(id: 7)]));
      final c = build(h);
      await c.load();

      await c.toggleFavorite();

      expect(c.isFavorite, isFalse);
      expect(h.requests.any((r) => r.method == 'DELETE'), isTrue);
    });

    test('toggleFavorite ล้มเหลวคงสถานะเดิม', () async {
      final base = standardHandler();
      final h = Harness((req) {
        if (req.method == 'POST' && req.url.path == '/api/favorites/7') {
          return _json({'message': 'หอนี้ยังไม่เผยแพร่'}, 403);
        }
        return base(req);
      });
      final c = build(h);
      await c.load();

      final ok = await c.toggleFavorite();

      expect(ok, isFalse);
      expect(c.isFavorite, isFalse);
      expect(c.error, isA<ApiException>());
    });

    test('openChat คืน conversation id และส่ง dormitory_id', () async {
      final h = Harness(standardHandler());
      final c = build(h);
      await c.load();

      final id = await c.openChat();

      expect(id, 99);
      final req = h.requests.lastWhere((r) => r.url.path == '/api/conversations');
      expect(jsonDecode(req.body), {'dormitory_id': 7});
      expect(c.busy, isFalse);
    });

    test('submitReview ตรวจ rating ก่อนส่ง และไม่ส่ง body ว่าง', () async {
      final h = Harness(standardHandler());
      final c = build(h);
      await c.load();

      expect(await c.submitReview(rating: 0), isFalse);
      expect(await c.submitReview(rating: 6), isFalse);
      expect(
        h.requests.any((r) => r.method == 'POST' && r.url.path == '/api/dormitories/7/reviews'),
        isFalse,
        reason: 'rating ผิดต้องไม่ยิง POST',
      );

      expect(await c.submitReview(rating: 4, body: '   '), isTrue);
      final req = h.requests.lastWhere((r) => r.url.path == '/api/dormitories/7/reviews');
      expect(jsonDecode(req.body), {'rating': 4});
    });

    test('submitReview ส่ง body ที่ตัดช่องว่างแล้ว', () async {
      final h = Harness(standardHandler());
      final c = build(h);
      await c.load();

      await c.submitReview(rating: 5, body: '  ห้องสะอาด  ');

      final req = h.requests.lastWhere((r) => r.url.path == '/api/dormitories/7/reviews');
      expect(jsonDecode(req.body), {'rating': 5, 'body': 'ห้องสะอาด'});
    });
  });
}
