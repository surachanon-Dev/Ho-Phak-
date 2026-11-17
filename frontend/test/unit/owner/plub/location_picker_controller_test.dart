// ผู้รับผิดชอบ: Plub (เจ้าของหอ)
// ไฟล์นี้เป็นเทสต์ unit ของ controller ที่ระบุในชื่อ group
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/owner/controllers/location_picker_controller.dart';
import 'package:hopak_frontend/shared/widgets/dorm_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('เริ่มที่ตำแหน่งเริ่มต้นที่ส่งมา ถ้าไม่ส่งใช้จุดกึ่งกลาง MFU', () {
    final a = LocationPickerController(initial: const LatLng(19.5, 99.5));
    expect(a.center, const LatLng(19.5, 99.5));
    final b = LocationPickerController();
    expect(b.center, mfuCenter);
    expect(b.distanceFromMfuLabel, '0.0');
  });

  test('setCenter เปลี่ยนจุดและระยะจาก MFU ตามจุดที่ลากไป', () {
    final c = LocationPickerController();
    var notifications = 0;
    c.addListener(() => notifications++);

    c.setCenter(const LatLng(19.9, 99.9));
    c.setCenter(const LatLng(19.9, 99.9));

    expect(c.center, const LatLng(19.9, 99.9));
    expect(notifications, 1, reason: 'ค่าเดิมไม่แจ้งซ้ำ');
    expect(c.distanceFromMfuLabel, isNot('0.0'));
  });

  test('useMyLocation ได้ตำแหน่งแล้วเลื่อนจุดกึ่งกลาง', () async {
    final c = LocationPickerController(
      deviceLocation: () async => const DeviceLocationResult.ok(LatLng(19.9, 99.9)),
    );

    expect(await c.useMyLocation(), isTrue);

    expect(c.center, const LatLng(19.9, 99.9));
    expect(c.locating, isFalse);
    expect(c.message, isNull);
  });

  test('ไม่ได้รับสิทธิ์ตำแหน่ง คืน false และเก็บข้อความให้แสดง', () async {
    final c = LocationPickerController(
      initial: const LatLng(19.5, 99.5),
      deviceLocation: () async =>
          const DeviceLocationResult.failed('Location permission was not granted'),
    );

    expect(await c.useMyLocation(), isFalse);

    expect(c.message, 'Location permission was not granted');
    expect(c.center, const LatLng(19.5, 99.5), reason: 'จุดเดิมไม่เปลี่ยน');
  });

  test('เกิด exception ตอนขอตำแหน่งเก็บข้อความทั่วไป', () async {
    final c = LocationPickerController(
      deviceLocation: () async => throw StateError('gps down'),
    );

    expect(await c.useMyLocation(), isFalse);
    expect(c.message, 'Could not get your location');
    expect(c.locating, isFalse);
  });

  test('ระหว่างกำลังขอตำแหน่งเรียกซ้ำจะไม่ทำงาน', () async {
    var calls = 0;
    final c = LocationPickerController(
      deviceLocation: () async {
        calls++;
        return const DeviceLocationResult.ok(LatLng(19.9, 99.9));
      },
    );

    final first = c.useMyLocation();
    expect(c.locating, isTrue);
    expect(await c.useMyLocation(), isFalse);
    expect(await first, isTrue);
    expect(calls, 1);
  });
}
