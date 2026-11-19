// ผู้รับผิดชอบ: Plub (เจ้าของหอ)
// unit test: OwnerDormFormController (ฟอร์มเพิ่ม/แก้ไขหอ ตรวจกติกา และบันทึก)
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:hopak_frontend/model/dorm_document.dart';
import 'package:hopak_frontend/model/dorm_utilities.dart';
import 'package:hopak_frontend/model/dormitory.dart';
import 'package:hopak_frontend/modules/owner/dorm_form/controller/owner_dorm_form_controller.dart';
import 'package:hopak_frontend/services/dormitory_service.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../helpers/fake_backend.dart';
import '../../../helpers/owner_data.dart';

UploadFile photo([String name = 'a.jpg']) =>
    UploadFile(bytes: Uint8List.fromList([1, 2, 3]), filename: name);

DormDocument document() =>
    DormDocument(name: 'deed.pdf', sizeBytes: 3, bytes: Uint8List(3));

/// ฟอร์มเพิ่มหอใหม่ที่กรอกครบทุกช่อง (ยังไม่มีรูปและเอกสาร)
OwnerDormFormController filledForm(DormitoryService dorms) {
  return OwnerDormFormController(existing: null, dorms: dorms)
    ..setName('Baan Suan')
    ..setPrice('3200')
    ..setTotalRooms('10')
    ..setAvailableRooms('4')
    ..setLocation(const LatLng(19.95, 99.89));
}

Map<String, Object> saveRoutes({int id = 5}) => ownerRoutes(
  extra: {
    'POST /api/owner/dormitories': {'id': id},
    'PUT /api/owner/dormitories/$id': {'ok': true},
    'PUT /api/owner/dormitories/$id/utilities': {'ok': true},
    'POST /api/owner/dormitories/$id/document': {'ok': true},
    'POST /api/owner/dormitories/$id/images': {'ok': true},
  },
);

void main() {
  group('Validation', () {
    late OwnerDormFormController form;

    setUp(() {
      form = OwnerDormFormController(
        existing: null,
        dorms: fakeBackend(ownerRoutes()).dormitories,
      );
    });

    test('1. an empty form is invalid and shows required errors', () {
      expect(form.isEdit, isFalse);
      expect(form.isValid, isFalse);
      expect(form.validateName(), isNotNull);
      expect(form.validatePrice(), isNotNull);
      expect(form.hasLocation, isFalse);
    });

    test('2. price must be a whole number between 1 and 1,000,000', () {
      form.setPrice('abc');
      expect(form.validatePrice(), 'Enter a whole number');
      form.setPrice('0');
      expect(form.validatePrice(), 'Price must be between 1 and 1,000,000 THB');
      form.setPrice('1000001');
      expect(form.validatePrice(), 'Price must be between 1 and 1,000,000 THB');
      form.setPrice('3200');
      expect(form.validatePrice(), isNull);
    });

    test('3. available rooms cannot exceed total rooms', () {
      form
        ..setTotalRooms('10')
        ..setAvailableRooms('11');
      expect(
        form.validateAvailableRooms(),
        'Available rooms cannot exceed total rooms',
      );
      form.setAvailableRooms('10');
      expect(form.validateAvailableRooms(), isNull);
    });

    test('4. a utility rate is only checked in Set price mode', () {
      form.setWaterMode(UtilityMode.included);
      expect(form.validateWaterRate(), isNull);
      expect(form.validateWaterBilling(), isNull);

      form.setWaterMode(UtilityMode.setPrice);
      expect(form.validateWaterRate(), 'Enter the rate');

      form.setWaterRate('8');
      expect(form.validateWaterRate(), isNull);
      expect(form.validateWaterBilling(), 'Choose how it is billed');

      form.setWaterType(BillingType.perUnit);
      expect(form.validateWaterBilling(), isNull);
    });

    test('5. setLocation stores the point and builds currentLocation', () {
      form.setLocation(const LatLng(19.95, 99.89));

      expect(form.hasLocation, isTrue);
      expect(form.currentLocation!.latitude, closeTo(19.95, 0.000001));
      expect(form.currentLocation!.longitude, closeTo(99.89, 0.000001));
    });

    test('6. toggleAmenity selects and unselects an amenity', () {
      form.toggleAmenity(2);
      expect(form.amenityIds, {2});
      form.toggleAmenity(2);
      expect(form.amenityIds, isEmpty);
    });

    test('7. pickLimit shrinks as photos are added', () {
      expect(form.pickLimit, 5);
      form.addPending([photo(), photo(), photo()]);
      expect(form.pickLimit, 5);
      form.addPending([photo(), photo(), photo()]);
      expect(form.pending, hasLength(6));
      form.removePending(0);
      expect(form.pending, hasLength(5));
    });
  });

  group('Editing an existing dorm', () {
    test('8. the form starts with the values of the dorm', () {
      final dorm = Dormitory.fromJson(
        ownerDormJson(id: 1, name: 'Baan Suan', price: 3200, total: 10),
      );
      final form = OwnerDormFormController(
        existing: dorm,
        dorms: fakeBackend(ownerRoutes()).dormitories,
      );

      expect(form.isEdit, isTrue);
      expect(form.name, 'Baan Suan');
      expect(form.price, '3200');
      expect(form.totalRooms, '10');
      expect(form.hasLocation, isTrue);
      expect(form.isValid, isTrue);
    });

    test('9. loadExtras fills the amenity catalog', () async {
      final form = OwnerDormFormController(
        existing: null,
        dorms: fakeBackend(ownerRoutes()).dormitories,
      );

      expect(await form.loadExtras(), isTrue);

      expect(form.catalog.map((a) => a.name), ['Wi-Fi', 'Parking']);
    });
  });

  group('Saving', () {
    test('10. an invalid form is not sent', () async {
      final requests = <http.Request>[];
      final form = OwnerDormFormController(
        existing: null,
        dorms: fakeBackend(saveRoutes(), requests: requests).dormitories,
      );

      expect(await form.save(), isNull);
      expect(requests.where((r) => r.method == 'POST'), isEmpty);
    });

    test('11. a new dorm needs at least one photo', () async {
      final form = filledForm(fakeBackend(saveRoutes()).dormitories)
        ..setDocument(document());

      expect(await form.save(), isNull);

      expect(form.error, isA<StateError>());
      expect(form.error.toString(), contains('at least 1 photo'));
    });

    test('12. a new dorm needs an ownership document', () async {
      final form = filledForm(fakeBackend(saveRoutes()).dormitories)
        ..addPending([photo()]);

      expect(await form.save(), isNull);

      expect(form.error.toString(), contains('ownership document'));
    });

    test('13. saving a new dorm posts it and uploads the photos', () async {
      final requests = <http.Request>[];
      final form = filledForm(
        fakeBackend(saveRoutes(id: 5), requests: requests).dormitories,
      )..addPending([photo()]);
      form.setDocument(document());

      final result = await form.save();

      expect(result!.dormId, 5);
      expect(result.photoError, isNull);
      final post = requests.firstWhere(
        (r) => r.method == 'POST' && r.url.path == '/api/owner/dormitories',
      );
      final body = jsonDecode(post.body) as Map<String, dynamic>;
      expect(body['name'], 'Baan Suan');
      expect(body['price_per_month'], 3200);
      expect(body['total_rooms'], 10);
      expect(
        requests.any((r) => r.url.path == '/api/owner/dormitories/5/images'),
        isTrue,
      );
      expect(form.saving, isFalse);
    });

    test(
      '14. a photo upload failure is reported but the dorm is kept',
      () async {
        final routes = saveRoutes(id: 5)
          ..remove('POST /api/owner/dormitories/5/images');
        final form = filledForm(fakeBackend(routes).dormitories)
          ..addPending([photo()]);
        form.setDocument(document());

        final result = await form.save();

        expect(result!.dormId, 5);
        expect(result.photoError, startsWith('Dorm saved, but photos'));
      },
    );

    test(
      '15. a backend error while saving keeps the error and returns null',
      () async {
        final routes = saveRoutes()..remove('POST /api/owner/dormitories');
        final form = filledForm(fakeBackend(routes).dormitories)
          ..addPending([photo()]);
        form.setDocument(document());

        expect(await form.save(), isNull);

        expect(form.error, isA<ApiException>());
        expect(form.saving, isFalse);
      },
    );

    test('16. editing a dorm sends PUT and needs no new photo', () async {
      final requests = <http.Request>[];
      final dorm = Dormitory.fromJson(ownerDormJson(id: 1));
      final form = OwnerDormFormController(
        existing: dorm,
        dorms: fakeBackend(
          ownerRoutes(
            extra: {
              'PUT /api/owner/dormitories/1': {'ok': true},
              'PUT /api/owner/dormitories/1/utilities': {'ok': true},
            },
          ),
          requests: requests,
        ).dormitories,
      )..setPrice('3500');

      final result = await form.save();

      expect(result!.dormId, 1);
      final put = requests.firstWhere(
        (r) => r.method == 'PUT' && r.url.path == '/api/owner/dormitories/1',
      );
      expect(jsonDecode(put.body)['price_per_month'], 3500);
    });
  });

  group('Photos of an existing dorm', () {
    OwnerDormFormController editForm(Map<String, Object> routes) =>
        OwnerDormFormController(
          existing: Dormitory.fromJson(ownerDormJson(id: 1)),
          dorms: fakeBackend(routes).dormitories,
        );

    test('17. uploadImages is not allowed for a new dorm', () async {
      final form = OwnerDormFormController(
        existing: null,
        dorms: fakeBackend(ownerRoutes()).dormitories,
      );

      expect(await form.uploadImages([photo()]), isFalse);
    });

    test(
      '18. uploadImages rejects an empty pick or more than 5 files',
      () async {
        final form = editForm(ownerRoutes(dorms: [ownerDormJson(id: 1)]));

        expect(await form.uploadImages([]), isFalse);
        expect(
          await form.uploadImages(List.generate(6, (i) => photo('$i.jpg'))),
          isFalse,
        );
      },
    );

    test('19. uploadImages sends the files and reloads the list', () async {
      final form = editForm(
        ownerRoutes(
          dorms: [ownerDormJson(id: 1)],
          extra: {
            'POST /api/owner/dormitories/1/images': {'ok': true},
          },
        ),
      );

      expect(await form.uploadImages([photo()]), isTrue);
      expect(form.busyImages, isFalse);
    });

    test('20. deleteImage that fails keeps the error', () async {
      final form = editForm(ownerRoutes(dorms: [ownerDormJson(id: 1)]));

      final ok = await form.deleteImage(
        DormImage(id: 3, filePath: 'uploads/a.jpg', sortOrder: 0),
      );

      expect(ok, isFalse);
      expect(form.error, isA<ApiException>());
    });
  });
}
