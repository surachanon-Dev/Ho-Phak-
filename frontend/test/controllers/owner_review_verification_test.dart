import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/controller/owner/api_owner_extras.dart';
import 'package:hopak_frontend/controller/owner/dormitory_controller.dart';
import 'package:hopak_frontend/controller/owner/owner_review_and_verification_controllers.dart';
import 'package:hopak_frontend/controller/owner/verification_controller.dart';
import 'package:hopak_frontend/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> _dorm(int id, String name) => {
  'id': id,
  'owner_id': 21,
  'name': name,
  'zone': 'หน้ามอ',
  'latitude': '19.88',
  'longitude': '99.83',
  'price_per_month': 3000,
  'total_rooms': 5,
  'available_rooms': 2,
  'status': 'published',
};

Map<String, dynamic> _review(int id, int rating) => {
  'id': id,
  'rating': rating,
  'body': 'รีวิว $id',
  'created_at': '2026-11-17',
};

/// เซิร์ฟเวอร์จำลองสำหรับหน้ารีวิวของเจ้าของ (2 หอ, รีวิว 3 รายการ)
http.Response _ownerRoutes(http.Request req, {List<int>? reportedIds}) {
  final p = req.url.path;
  if (req.method == 'GET' && p == '/api/owner/dormitories') {
    return _json({'dormitories': [_dorm(1, 'หอ A'), _dorm(2, 'หอ B')]});
  }
  if (req.method == 'GET' && p == '/api/owner/dormitories/1/reviews') {
    return _json({'reviews': [_review(10, 5), _review(11, 3)]});
  }
  if (req.method == 'GET' && p == '/api/owner/dormitories/2/reviews') {
    return _json({'reviews': [_review(20, 4)]});
  }
  if (req.method == 'GET' && p == '/api/owner/review-reports') {
    return _json({
      'reports': (reportedIds ?? const <int>[])
          .map((id) => {'review_id': id, 'reason': 'เหตุผล'})
          .toList(),
    });
  }
  if (req.method == 'POST' && p.endsWith('/report')) {
    return _json({'message': 'ส่งรายงานรีวิวแล้ว'}, 201);
  }
  return _json({'message': 'not mocked ${req.method} $p'}, 404);
}

DormitoryController _dormCtl(http.Client client) {
  final api = ApiClient(tokenProvider: () => 't', client: client);
  return DormitoryController(api, ApiOwnerExtras(api));
}

void main() {
  group('MyReviewsController', () {
    test('load รวมรีวิวทุกหอและชื่อหอ', () async {
      final c = MyReviewsController(_dormCtl(MockClient((req) async => _ownerRoutes(req))));

      expect(await c.load(), isTrue);

      expect(c.visible.length, 3);
      expect(c.dormNames, ['หอ A', 'หอ B']);
      expect(c.showFullLoader, isFalse);
    });

    test('ค่าเฉลี่ยตามตัวกรอง', () async {
      final c = MyReviewsController(_dormCtl(MockClient((req) async => _ownerRoutes(req))));
      await c.load();

      expect(c.average, closeTo((5 + 3 + 4) / 3, 1e-9));
      c.setFilter('หอ A');
      expect(c.visible.map((e) => e.review.id), [10, 11]);
      expect(c.average, 4.0);
      c.setFilter('ไม่มี');
      expect(c.filter, isNull, reason: 'ชื่อที่ไม่มีจะเป็นทุกหอ');
    });

    test('isReported อ่านจากรายการ report ของ backend', () async {
      final c = MyReviewsController(_dormCtl(MockClient((req) async => _ownerRoutes(req, reportedIds: [11]))));
      await c.load();
      expect(c.isReported(11), isTrue);
      expect(c.isReported(10), isFalse);
    });

    test('report สำเร็จส่ง POST และโหลดรายการ report ใหม่', () async {
      final requests = <http.Request>[];
      final c = MyReviewsController(_dormCtl(MockClient((req) async {
        requests.add(req);
        return _ownerRoutes(req, reportedIds: requests.any((r) => r.method == 'POST') ? [10] : []);
      })));
      await c.load();

      final ok = await c.report(10, '  เนื้อหาไม่เหมาะสม  ');

      expect(ok, isTrue);
      final post = requests.firstWhere((r) => r.method == 'POST');
      expect(post.url.path, '/api/owner/reviews/10/report');
      expect(jsonDecode(post.body), {'reason': 'เนื้อหาไม่เหมาะสม'});
      expect(c.isReported(10), isTrue);
    });

    test('เหตุผลว่างหรือยาวเกิน 300 ตัวไม่ยิง request', () async {
      final requests = <http.Request>[];
      final c = MyReviewsController(_dormCtl(MockClient((req) async {
        requests.add(req);
        return _ownerRoutes(req);
      })));
      await c.load();
      requests.clear();

      expect(await c.report(10, '   '), isFalse);
      expect(await c.report(10, 'ก' * (MyReviewsController.maxReportReasonLength + 1)), isFalse);
      expect(requests.where((r) => r.method == 'POST'), isEmpty);
    });

    test('report ซ้ำ (409) คืน false และเก็บ error', () async {
      final c = MyReviewsController(_dormCtl(MockClient((req) async {
        if (req.method == 'POST') return _json({'message': 'รายงานรีวิวนี้ไปแล้ว'}, 409);
        return _ownerRoutes(req);
      })));
      await c.load();

      expect(await c.report(10, 'เหตุผล'), isFalse);
      expect(c.error, isA<ApiException>());
    });

    test('load ล้มเหลวคืน false', () async {
      final c = MyReviewsController(_dormCtl(MockClient((req) async => _json({'message': 'x'}, 500))));
      expect(await c.load(), isFalse);
      expect(c.loading, isFalse);
    });
  });

  group('DocumentCheck', () {
    test('ยอมรับ pdf, jpg, jpeg, png โดยไม่สนตัวพิมพ์', () {
      for (final name in ['a.pdf', 'b.JPG', 'c.jpeg', 'd.Png']) {
        expect(DocumentCheck.validate(filename: name, sizeBytes: 100), isNull, reason: name);
      }
    });

    test('ปฏิเสธนามสกุลอื่นและไฟล์ที่ไม่มีนามสกุล', () {
      expect(DocumentCheck.validate(filename: 'a.exe', sizeBytes: 1), isNotNull);
      expect(DocumentCheck.validate(filename: 'noext', sizeBytes: 1), isNotNull);
      expect(DocumentCheck.validate(filename: 'pdf', sizeBytes: 1), isNotNull);
    });

    test('ปฏิเสธไฟล์เกิน 10 MB และยอมรับพอดี 10 MB', () {
      expect(
        DocumentCheck.validate(filename: 'a.pdf', sizeBytes: VerificationController.maxDocumentBytes + 1),
        isNotNull,
      );
      expect(
        DocumentCheck.validate(filename: 'a.pdf', sizeBytes: VerificationController.maxDocumentBytes),
        isNull,
      );
    });
  });

  group('VerificationScreenController', () {
    VerificationScreenController build(http.Client client) {
      final api = ApiClient(tokenProvider: () => 't', client: client);
      return VerificationScreenController(VerificationController(api));
    }

    test('ยังไม่เคยส่ง canSubmit เป็น true', () async {
      final c = build(MockClient((req) async => _json({'verification': null})));
      await c.load();
      expect(c.current, isNull);
      expect(c.canSubmit, isTrue);
    });

    test('สถานะ pending ส่งซ้ำไม่ได้ แต่ rejected ส่งใหม่ได้', () async {
      var status = 'pending';
      final c = build(MockClient((req) async => _json({
        'verification': {'id': 4, 'status': status, 'rejection_reason': 'เอกสารไม่ชัด'},
      })));
      await c.load();
      expect(c.canSubmit, isFalse);

      status = 'rejected';
      await c.load();
      expect(c.canSubmit, isTrue);
      expect(c.current?.reason, 'เอกสารไม่ชัด');
    });

    test('pick ไฟล์ผิดประเภทเก็บ pickError และไม่เลือกไฟล์', () async {
      final c = build(MockClient((req) async => _json({'verification': null})));
      final ok = c.pick(UploadFile(bytes: Uint8List(10), filename: 'x.docx'));
      expect(ok, isFalse);
      expect(c.picked, isNull);
      expect(c.pickError, isNotNull);
    });

    test('submit ไม่มีไฟล์ไม่ยิง request', () async {
      final requests = <http.Request>[];
      final c = build(MockClient((req) async {
        requests.add(req);
        return _json({'verification': null});
      }));
      await c.load();
      requests.clear();

      expect(await c.submit(), isFalse);
      expect(requests, isEmpty);
    });

    test('submit สำเร็จส่ง multipart แล้วโหลดสถานะใหม่', () async {
      final requests = <http.Request>[];
      var uploaded = false;
      final c = build(MockClient((req) async {
        requests.add(req);
        if (req.method == 'POST' && req.url.path == '/api/owner/verification') {
          uploaded = true;
          return _json({'message': 'ส่งเอกสารให้ admin ตรวจแล้ว'}, 201);
        }
        return _json({
          'verification': uploaded ? {'id': 4, 'status': 'pending'} : null,
        });
      }));
      await c.load();
      expect(c.pick(UploadFile(bytes: Uint8List.fromList([1, 2, 3]), filename: 'doc.pdf')), isTrue);

      final ok = await c.submit();

      expect(ok, isTrue);
      expect(c.picked, isNull);
      expect(c.current?.status, 'pending');
      final post = requests.firstWhere((r) => r.method == 'POST');
      expect(post.headers['content-type'] ?? '', contains('multipart/form-data'));
    });

    test('submit ที่ server ปฏิเสธคืน false และเก็บ error', () async {
      final c = build(MockClient((req) async {
        if (req.method == 'POST') return _json({'message': 'มีคำขอที่รอตรวจอยู่แล้ว'}, 409);
        return _json({'verification': null});
      }));
      await c.load();
      c.pick(UploadFile(bytes: Uint8List.fromList([1]), filename: 'doc.png'));

      expect(await c.submit(), isFalse);
      expect(c.error, isA<ApiException>());
      expect(c.saving, isFalse);
    });
  });
}
