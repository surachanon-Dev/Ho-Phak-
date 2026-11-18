// ผู้รับผิดชอบ: Plub (เจ้าของหอ)
// ไฟล์นี้เป็นเทสต์ unit ของ controller ที่ระบุในชื่อ group
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/owner/services/api_owner_extras.dart';
import 'package:hopak_frontend/features/owner/services/dormitory_service.dart';
import 'package:hopak_frontend/features/owner/validation/dormitory_rules.dart';
import 'package:hopak_frontend/features/owner/dorm_form/owner_dorm_form_controller.dart';
import 'package:hopak_frontend/shared/models/dormitory.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hopak_frontend/features/owner/models/dorm_utilities.dart';
import 'package:hopak_frontend/features/owner/models/dorm_document.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> _dormJson({int id = 1, List<Map<String, dynamic>> images = const []}) => {
  'id': id,
  'owner_id': 21,
  'name': 'หอ A',
  'zone': 'หลังมอ',
  'latitude': '19.88',
  'longitude': '99.83',
  'price_per_month': 3000,
  'total_rooms': 5,
  'available_rooms': 2,
  'status': 'published',
  'water_rate': '18.00',
  'water_billing_type': 'per_unit',
  'electricity_rate': null,
  'electricity_billing_type': null,
  'address': 'ที่อยู่',
  'description': 'รายละเอียด',
  'contact_phone': '0855500002',
  'amenity_ids': [1],
  'images': images,
};

/// ฟอร์มสำหรับเพิ่มหอใหม่ (ค่าครบ ผ่านกติกาทั้งหมด)
void _fillValid(OwnerDormFormController c) {
  c.setName('หอทดสอบ');
  c.setZone('หน้ามอ');
  c.setPrice('3500');
  c.setTotalRooms('10');
  c.setAvailableRooms('4');
  c.setWaterMode(UtilityMode.notSpecified);
  c.setElectricityMode(UtilityMode.notSpecified);
  c.setLocation(const LatLng(19.88, 99.83));
}

UploadFile _photo([String name = 'a.jpg']) =>
    UploadFile(bytes: Uint8List.fromList([1, 2, 3]), filename: name);

void main() {
  OwnerDormFormController build(List<http.Request> log,
      {Dormitory? existing,
      http.Response Function(http.Request req)? handler}) {
    final api = ApiClient(
      tokenProvider: () => 't',
      client: MockClient((req) async {
        log.add(req);
        if (handler != null) return handler(req);
        if (req.method == 'POST' && req.url.path == '/api/owner/dormitories') {
          return _json({'message': 'ส่งหอพักให้ admin ตรวจแล้ว', 'id': 42}, 201);
        }
        if (req.method == 'PUT' && req.url.path.endsWith('/utilities')) {
          return _json({'water': 'notSpecified', 'electricity': 'notSpecified'});
        }
        if (req.method == 'PUT' && req.url.path == '/api/owner/dormitories/1') {
          return _json({'message': 'แก้ไขแล้ว'});
        }
        if (req.method == 'GET' && req.url.path == '/api/owner/dormitories/1') {
          return _json({'dormitory': _dormJson(), 'latest_revision': null});
        }
        if (req.method == 'POST' && req.url.path == '/api/owner/dormitories/42/images') {
          return _json({'message': 'ok'}, 201);
        }
        if (req.method == 'POST' && req.url.path == '/api/owner/dormitories/42/document') {
          return _json({'message': 'ส่งเอกสารให้ admin ตรวจแล้ว'}, 201);
        }
        if (req.method == 'GET' && req.url.path == '/api/amenities') {
          return _json({'amenities': [{'id': 1, 'name': 'Wi-Fi'}, {'id': 2, 'name': 'CCTV'}]});
        }
        if (req.method == 'GET' && req.url.path == '/api/owner/dormitories/1/utilities') {
          return _json({'water': 'setPrice', 'electricity': 'notSpecified'});
        }
        return _json({'message': 'not mocked ${req.method} ${req.url.path}'}, 404);
      }),
    );
    return OwnerDormFormController(
      existing: existing,
      dorms: DormitoryService(api, ApiOwnerExtras(api)),
    );
  }

  group('DormitoryRules (กติกาที่ฟอร์มใช้)', () {
    test('required ปฏิเสธช่องว่าง', () {
      expect(DormitoryRules.required('  '), isNotNull);
      expect(DormitoryRules.required('x'), isNull);
    });

    test('price อยู่ในช่วง 1–1,000,000 และต้องเป็นจำนวนเต็ม', () {
      expect(DormitoryRules.price('0'), isNotNull);
      expect(DormitoryRules.price('1'), isNull);
      expect(DormitoryRules.price('1000000'), isNull);
      expect(DormitoryRules.price('1000001'), isNotNull);
      expect(DormitoryRules.price('12.5'), isNotNull);
    });

    test('totalRooms ห้ามติดลบ', () {
      expect(DormitoryRules.totalRooms('-1'), isNotNull);
      expect(DormitoryRules.totalRooms('0'), isNull);
    });

    test('availableRooms ห้ามเกินห้องทั้งหมด', () {
      expect(DormitoryRules.availableRooms('6', '5'), isNotNull);
      expect(DormitoryRules.availableRooms('5', '5'), isNull);
      expect(DormitoryRules.availableRooms('-1', '5'), isNotNull);
    });

    test('rate ว่างได้ แต่ต้องไม่ติดลบ', () {
      expect(DormitoryRules.rate(''), isNull);
      expect(DormitoryRules.rate('-2'), isNotNull);
      expect(DormitoryRules.rate('abc'), isNotNull);
    });

    test('rateRequired ต้องมีค่า และ billing ต้องเลือกเมื่อกรอกอัตรา', () {
      expect(DormitoryRules.rateRequired(''), isNotNull);
      expect(DormitoryRules.billing(null, '18'), isNotNull);
      expect(DormitoryRules.billing(null, ''), isNull);
      expect(DormitoryRules.billing('per_unit', '18'), isNull);
    });

    test('pickLimit ไม่เกิน 5 ต่อครั้งและไม่เกิน 10 รูปต่อหอ', () {
      expect(DormitoryRules.pickLimit(0), 5);
      expect(DormitoryRules.pickLimit(7), 3);
      expect(DormitoryRules.pickLimit(10), 0);
    });
  });

  group('OwnerDormFormController', () {
    test('หอใหม่เริ่มด้วยค่าว่างและไม่ผ่านการตรวจ', () {
      final c = build([]);
      expect(c.isEdit, isFalse);
      expect(c.isValid, isFalse);
      expect(c.hasLocation, isFalse);
      expect(c.validateName(), isNotNull);
    });

    test('หอที่มีอยู่แล้วเติมค่าจากข้อมูลเดิม', () {
      final existing = Dormitory.fromJson(_dormJson());
      final c = build([], existing: existing);
      expect(c.isEdit, isTrue);
      expect(c.name, 'หอ A');
      expect(c.zone, 'หลังมอ');
      expect(c.waterMode, UtilityMode.setPrice, reason: 'มีอัตราน้ำจึงเป็น set price');
      expect(c.electricityMode, UtilityMode.notSpecified);
      expect(c.images, isEmpty);
      expect(c.hasLocation, isTrue);
    });

    test('กรอกครบแล้วฟอร์มผ่าน', () {
      final c = build([]);
      _fillValid(c);
      expect(c.isValid, isTrue);
    });

    test('ราคาเกินกติกา ฟอร์มไม่ผ่าน', () {
      final c = build([]);
      _fillValid(c);
      c.setPrice('0');
      expect(c.isValid, isFalse);
      expect(c.validatePrice(), isNotNull);
    });

    test('ห้องว่างเกินห้องทั้งหมดไม่ผ่าน', () {
      final c = build([]);
      _fillValid(c);
      c.setAvailableRooms('11');
      expect(c.validateAvailableRooms(), isNotNull);
      expect(c.isValid, isFalse);
    });

    test('ตั้งน้ำเป็น set price ต้องกรอกอัตราและวิธีคิด', () {
      final c = build([]);
      _fillValid(c);
      c.setWaterMode(UtilityMode.setPrice);
      expect(c.validateWaterRate(), isNotNull);
      c.setWaterRate('18');
      expect(c.validateWaterBilling(), isNotNull, reason: 'ยังไม่เลือกวิธีคิด');
      c.setWaterType('per_unit');
      expect(c.isValid, isTrue);
    });

    test('setLocation ตั้งพิกัดให้ hasLocation เป็น true', () {
      final c = build([]);
      _fillValid(c);
      c.setLocation(const LatLng(0, 0));
      expect(c.hasLocation, isTrue);
      final fresh = build([]);
      _fillValid(fresh);
      expect(fresh.hasLocation, isTrue);
    });

    test('toggleAmenity เพิ่มและลบ id', () {
      final c = build([]);
      c.toggleAmenity(3);
      expect(c.amenityIds, {3});
      c.toggleAmenity(3);
      expect(c.amenityIds, isEmpty);
    });

    test('addPending และ removePending จัดการรูปที่เลือกไว้ก่อนบันทึก', () {
      final c = build([]);
      c.addPending([_photo('a.jpg'), _photo('b.jpg')]);
      expect(c.pending.map((p) => p.filename), ['a.jpg', 'b.jpg']);
      c.removePending(0);
      expect(c.pending.map((p) => p.filename), ['b.jpg']);
    });

    test('save หอใหม่ที่ไม่มีรูปไม่ยิง request', () async {
      final log = <http.Request>[];
      final c = build(log);
      _fillValid(c);

      expect(await c.save(), isNull);
      expect(c.error, isA<StateError>());
      expect(log.where((r) => r.method == 'POST'), isEmpty);
    });

    test('save หอใหม่สำเร็จ: POST หอ, PUT utilities แล้วอัปโหลดรูป', () async {
      final log = <http.Request>[];
      final c = build(log);
      _fillValid(c);
      c.addPending([_photo()]);
      c.setDocument(DormDocument(name: 'deed.pdf', sizeBytes: 3, bytes: Uint8List.fromList([1, 2, 3])));

      final result = await c.save();

      expect(result?.dormId, 42);
      expect(result?.photoError, isNull);
      final post = log.firstWhere((r) => r.method == 'POST' && r.url.path == '/api/owner/dormitories');
      final body = jsonDecode(post.body) as Map<String, dynamic>;
      expect(body['name'], 'หอทดสอบ');
      expect(body['price_per_month'], 3500);
      expect(body.containsKey('water_rate'), isFalse, reason: 'ไม่ได้ตั้งอัตราน้ำ');
      expect(log.any((r) => r.method == 'PUT' && r.url.path == '/api/owner/dormitories/42/utilities'), isTrue);
      expect(log.any((r) => r.method == 'POST' && r.url.path == '/api/owner/dormitories/42/images'), isTrue);
      expect(log.any((r) => r.method == 'POST' && r.url.path == '/api/owner/dormitories/42/document'), isTrue);
      expect(c.saving, isFalse);
    });

    test('save สำเร็จแต่อัปโหลดรูปไม่ได้ คืน photoError', () async {
      final c = build([], handler: (req) {
        if (req.method == 'POST' && req.url.path == '/api/owner/dormitories') {
          return _json({'id': 42}, 201);
        }
        if (req.url.path.endsWith('/images')) return _json({'message': 'x'}, 500);
        return _json({'water': 'notSpecified', 'electricity': 'notSpecified'});
      });
      _fillValid(c);
      c.addPending([_photo()]);
      c.setDocument(DormDocument(name: 'deed.pdf', sizeBytes: 3, bytes: Uint8List.fromList([1, 2, 3])));

      final result = await c.save();

      expect(result?.dormId, 42);
      expect(result?.photoError, contains('Dorm saved, but photos were not uploaded'));
    });

    test('save หอใหม่ที่ไม่มีเอกสารความเป็นเจ้าของไม่ยิง request', () async {
      final log = <http.Request>[];
      final c = build(log);
      _fillValid(c);
      c.addPending([_photo()]);
      expect(await c.save(), isNull);
      expect(log, isEmpty);
      expect(c.error, isA<StateError>());
    });

    test('save หอที่มีอยู่แล้วใช้ PUT และไม่ต้องมีรูปใหม่', () async {
      final log = <http.Request>[];
      final c = build(log, existing: Dormitory.fromJson(_dormJson()));
      c.setPrice('3600');

      final result = await c.save();

      expect(result?.dormId, 1);
      expect(log.any((r) => r.method == 'PUT' && r.url.path == '/api/owner/dormitories/1'), isTrue);
    });

    test('save ฟอร์มไม่ผ่านไม่ยิง request', () async {
      final log = <http.Request>[];
      final c = build(log);
      c.addPending([_photo()]);
      expect(await c.save(), isNull);
      expect(log, isEmpty);
    });

    test('save ที่ server ตอบ error คืน null และเก็บ error', () async {
      final c = build([], handler: (req) => _json({'message': 'DB error'}, 500));
      _fillValid(c);
      c.addPending([_photo()]);
      c.setDocument(DormDocument(name: 'deed.pdf', sizeBytes: 3, bytes: Uint8List.fromList([1, 2, 3])));
      expect(await c.save(), isNull);
      expect(c.error, isA<ApiException>());
      expect(c.saving, isFalse);
    });

    test('loadExtras ดึง catalog, amenity ที่เลือก และโหมดค่าน้ำไฟ', () async {
      final c = build([], existing: Dormitory.fromJson(_dormJson()));

      expect(await c.loadExtras(), isTrue);

      expect(c.catalog.map((a) => a.name), ['Wi-Fi', 'CCTV']);
      expect(c.amenityIds, {1});
      expect(c.waterMode, UtilityMode.setPrice);
    });

    test('uploadImages และ deleteImage ของหอที่มีอยู่แล้ว', () async {
      final log = <http.Request>[];
      final c = build(log, existing: Dormitory.fromJson(_dormJson()), handler: (req) {
        if (req.method == 'POST' && req.url.path == '/api/owner/dormitories/1/images') {
          return _json({'message': 'ok'}, 201);
        }
        if (req.method == 'DELETE') return _json({'message': 'ok'});
        return _json({'dormitory': _dormJson(images: [
          {'id': 7, 'file_path': 'a.jpg', 'sort_order': 0},
        ]), 'latest_revision': null});
      });

      expect(await c.uploadImages([_photo()]), isTrue);
      expect(c.images.map((i) => i.id), [7]);

      final img = c.images.single;
      expect(await c.deleteImage(img), isTrue);
      expect(log.any((r) => r.method == 'DELETE' && r.url.path == '/api/owner/dormitories/1/images/7'), isTrue);
    });

    test('uploadImages ปฏิเสธเกินจำนวนต่อครั้งหรือเกิน 10 รูป', () async {
      final log = <http.Request>[];
      final c = build(log, existing: Dormitory.fromJson(_dormJson()));
      final six = List.generate(6, (i) => _photo('$i.jpg'));
      expect(await c.uploadImages(six), isFalse);
      expect(await c.uploadImages([]), isFalse);
      expect(log.where((r) => r.method == 'POST'), isEmpty);
    });

    test('uploadImages ของหอใหม่ไม่ทำงาน (ยังไม่มี id)', () async {
      final c = build([]);
      expect(await c.uploadImages([_photo()]), isFalse);
    });

    test('setDocument เก็บชื่อและขนาดเอกสาร (ยังไม่มี endpoint อัปโหลดเอกสาร)', () {
      final c = build([]);
      c.setDocument(const DormDocument(name: 'deed.pdf', sizeBytes: 1024));
      expect(c.document?.name, 'deed.pdf');
    });
  });
}
