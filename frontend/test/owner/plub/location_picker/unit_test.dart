// ผู้รับผิดชอบ: Plub (เจ้าของหอ)
// unit test: LocationPickerController (ปักหมุดตำแหน่งหอ)
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/modules/owner/location_picker/controller/location_picker_controller.dart';
import 'package:hopak_frontend/widgets/dorm_map.dart' show mfuCenter;
import 'package:latlong2/latlong.dart';

void main() {
  test('1. starts at MFU when there is no initial point', () {
    final c = LocationPickerController();

    expect(c.center, mfuCenter);
    expect(c.distanceFromMfuLabel, '0.0');
    expect(c.locating, isFalse);
  });

  test('2. starts at the given initial point', () {
    final c = LocationPickerController(initial: const LatLng(19.95, 99.89));

    expect(c.center, const LatLng(19.95, 99.89));
  });

  test('3. setCenter moves the pin and updates the distance', () {
    final c = LocationPickerController();
    var notified = 0;
    c.addListener(() => notified++);

    c.setCenter(const LatLng(19.9801, 99.8323)); // เหนือ MFU ประมาณ 11 กม.

    expect(c.center.latitude, 19.9801);
    expect(double.parse(c.distanceFromMfuLabel), greaterThan(10));
    expect(notified, 1);
  });

  test('4. setCenter to the same point does not notify', () {
    final c = LocationPickerController(initial: const LatLng(19.95, 99.89));
    var notified = 0;
    c.addListener(() => notified++);

    c.setCenter(const LatLng(19.95, 99.89));

    expect(notified, 0);
  });

  test('5. useMyLocation moves the pin to the device location', () async {
    final c = LocationPickerController(
      deviceLocation: () async =>
          const DeviceLocationResult.ok(LatLng(19.9, 99.8)),
    );

    expect(await c.useMyLocation(), isTrue);

    expect(c.center, const LatLng(19.9, 99.8));
    expect(c.message, isNull);
    expect(c.locating, isFalse);
  });

  test('6. useMyLocation shows the message when it is refused', () async {
    final c = LocationPickerController(
      initial: const LatLng(19.95, 99.89),
      deviceLocation: () async => const DeviceLocationResult.failed(
        'Location permission was not granted',
      ),
    );

    expect(await c.useMyLocation(), isFalse);

    expect(c.message, 'Location permission was not granted');
    expect(c.center, const LatLng(19.95, 99.89)); // หมุดไม่ขยับ
  });

  test('7. useMyLocation that throws shows a generic message', () async {
    final c = LocationPickerController(
      deviceLocation: () async => throw Exception('gps off'),
    );

    expect(await c.useMyLocation(), isFalse);

    expect(c.message, 'Could not get your location');
    expect(c.locating, isFalse);
  });
}
