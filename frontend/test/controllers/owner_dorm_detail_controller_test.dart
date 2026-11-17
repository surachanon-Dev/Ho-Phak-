import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/owner/services/api_owner_extras.dart';
import 'package:hopak_frontend/features/owner/services/dormitory_service.dart';
import 'package:hopak_frontend/features/owner/controllers/owner_dorm_detail_controller.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> _dormJson({String status = 'published'}) => {
  'id': 1,
  'owner_id': 21,
  'name': 'หอ A',
  'zone': 'หน้ามอ',
  'latitude': '19.88',
  'longitude': '99.83',
  'price_per_month': 3000,
  'total_rooms': 5,
  'available_rooms': 2,
  'status': status,
  'water_rate': '18.00',
  'water_billing_type': 'per_unit',
  'electricity_rate': null,
  'electricity_billing_type': null,
  'amenity_ids': [1],
  'images': <Map<String, dynamic>>[],
};

/// เซิร์ฟเวอร์จำลองสำหรับหน้ารายละเอียดหอของเจ้าของ
http.Response _route(http.Request req, {String status = 'published', List<int> reviewRatings = const [5, 3]}) {
  final p = req.url.path;
  final m = req.method;
  if (m == 'GET' && p == '/api/owner/dormitories/1') {
    return _json({'dormitory': _dormJson(status: status), 'latest_revision': null});
  }
  if (m == 'GET' && p == '/api/owner/dormitories/1/reviews') {
    return _json({
      'reviews': [
        for (var i = 0; i < reviewRatings.length; i++)
          {'id': 100 + i, 'rating': reviewRatings[i], 'body': 'รีวิว $i', 'created_at': '2026-11-17'},
      ],
      'summary': {'review_count': reviewRatings.length},
    });
  }
  if (m == 'GET' && p == '/api/amenities') {
    return _json({
      'amenities': [
        {'id': 1, 'name': 'Wi-Fi'},
        {'id': 2, 'name': 'CCTV'},
      ],
    });
  }
  if (m == 'GET' && p == '/api/owner/dormitories/1/utilities') {
    return _json({'water': 'setPrice', 'electricity': 'notSpecified'});
  }
  if (m == 'PATCH' && p == '/api/owner/dormitories/1/visibility') {
    return _json({'message': 'เปลี่ยนการแสดงผลแล้ว', 'status': 'hidden'});
  }
  if (m == 'DELETE' && p == '/api/owner/dormitories/1') {
    return _json({'message': 'ลบหอพักแล้ว'});
  }
  return _json({'message': 'not mocked $m $p'}, 404);
}

void main() {
  OwnerDormDetailController build(List<http.Request> log,
      {String status = 'published', List<int> ratings = const [5, 3]}) {
    final api = ApiClient(
      tokenProvider: () => 't',
      client: MockClient((req) async {
        log.add(req);
        return _route(req, status: status, reviewRatings: ratings);
      }),
    );
    return OwnerDormDetailController(
      dormitoryId: 1,
      dorms: DormitoryService(api, ApiOwnerExtras(api)),
    );
  }

  test('load โหลดหอ รีวิว amenities และค่าน้ำไฟ', () async {
    final c = build([]);
    expect(c.loading, isTrue);

    expect(await c.load(), isTrue);

    expect(c.dorm?.name, 'หอ A');
    expect(c.reviews.length, 2);
    expect(c.amenities.map((a) => a.name), ['Wi-Fi']);
    expect(c.utilities, isNotNull);
    expect(c.loading, isFalse);
    expect(c.changed, isFalse);
  });

  test('คะแนนเฉลี่ยและรีวิวล่าสุด', () async {
    final c = build([], ratings: [5, 3, 4]);
    await c.load();
    expect(c.averageRating, closeTo(4.0, 1e-9));
    expect(c.latestReview?.rating, 5);
  });

  test('ไม่มีรีวิวให้ค่าเฉลี่ยเป็น null', () async {
    final c = build([], ratings: []);
    await c.load();
    expect(c.averageRating, isNull);
    expect(c.latestReview, isNull);
  });

  test('toggleVisibility เรียก PATCH แล้วตั้ง changed และโหลดใหม่', () async {
    final log = <http.Request>[];
    final c = build(log);
    await c.load();
    log.clear();

    expect(await c.toggleVisibility(), isTrue);

    expect(c.changed, isTrue);
    expect(log.any((r) => r.method == 'PATCH' && r.url.path == '/api/owner/dormitories/1/visibility'), isTrue);
    expect(log.any((r) => r.method == 'GET' && r.url.path == '/api/owner/dormitories/1'), isTrue,
        reason: 'โหลดข้อมูลใหม่หลังสลับ');
    expect(c.busy, isFalse);
  });

  test('delete สำเร็จตั้ง changed และคืน true', () async {
    final log = <http.Request>[];
    final c = build(log);
    await c.load();

    expect(await c.delete(), isTrue);

    expect(c.changed, isTrue);
    expect(log.any((r) => r.method == 'DELETE' && r.url.path == '/api/owner/dormitories/1'), isTrue);
  });

  test('delete ไม่ทำงานถ้ายังไม่มีหอ', () async {
    final log = <http.Request>[];
    final c = build(log);
    expect(await c.delete(), isFalse);
    expect(log, isEmpty);
  });

  test('reloadAfterEdit ตั้ง changed และโหลดใหม่', () async {
    final c = build([]);
    expect(await c.reloadAfterEdit(), isTrue);
    expect(c.changed, isTrue);
    expect(c.dorm, isNotNull);
  });

  test('load ล้มเหลวเก็บ error และ loading เป็น false', () async {
    final api = ApiClient(
      tokenProvider: () => 't',
      client: MockClient((req) async => _json({'message': 'x'}, 500)),
    );
    final c = OwnerDormDetailController(
      dormitoryId: 1,
      dorms: DormitoryService(api, ApiOwnerExtras(api)),
    );
    expect(await c.load(), isFalse);
    expect(c.error, isA<ApiException>());
    expect(c.loading, isFalse);
  });
}
