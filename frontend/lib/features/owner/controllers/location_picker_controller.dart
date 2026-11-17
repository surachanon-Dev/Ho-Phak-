import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../ui/format.dart';
import '../../widgets/dorm_map.dart';

/// ผลการขอตำแหน่งปัจจุบันของเครื่อง
class DeviceLocationResult {
  const DeviceLocationResult.ok(this.position) : message = null;
  const DeviceLocationResult.failed(this.message) : position = null;

  final LatLng? position;

  /// ข้อความที่ต้องแสดงเมื่อขอตำแหน่งไม่ได้
  final String? message;
}

/// หน้าปักหมุดตำแหน่งหอ: เก็บจุดกึ่งกลางแผนที่, ระยะจาก MFU, และการขอตำแหน่งเครื่อง
///
/// [deviceLocation] ถูกฉีดเข้ามาเพื่อทดสอบได้ ค่าเริ่มต้นใช้ Geolocator จริง
class LocationPickerController extends ChangeNotifier {
  LocationPickerController({LatLng? initial, Future<DeviceLocationResult> Function()? deviceLocation})
    : _center = initial ?? mfuCenter,
      _deviceLocation = deviceLocation ?? _geolocatorLocation;

  final Future<DeviceLocationResult> Function() _deviceLocation;

  LatLng _center;
  bool _locating = false;
  String? _message;

  /// จุดกึ่งกลางแผนที่ = ตำแหน่งที่จะบันทึก
  LatLng get center => _center;

  /// กำลังขอตำแหน่งเครื่องอยู่
  bool get locating => _locating;

  /// ข้อความแจ้งผู้ใช้ล่าสุด (เช่น ไม่ได้รับสิทธิ์ตำแหน่ง) หรือ null
  String? get message => _message;

  /// ระยะจาก MFU เป็นกิโลเมตร (ทศนิยม 1 ตำแหน่ง) ใช้แสดงใต้หมุด
  String get distanceFromMfuLabel => kmFromMfu(_center.latitude, _center.longitude);

  /// แผนที่เลื่อนไปยังจุดใหม่ (เรียกจากการลากแผนที่)
  void setCenter(LatLng p) {
    if (p == _center) return;
    _center = p;
    notifyListeners();
  }

  /// ขอตำแหน่งเครื่องแล้วให้แผนที่เลื่อนไปที่นั่น คืน true เมื่อได้ตำแหน่ง
  Future<bool> useMyLocation() async {
    if (_locating) return false;
    _locating = true;
    _message = null;
    notifyListeners();
    try {
      final result = await _deviceLocation();
      if (result.position != null) {
        _center = result.position!;
        return true;
      }
      _message = result.message;
      return false;
    } catch (_) {
      _message = 'Could not get your location';
      return false;
    } finally {
      _locating = false;
      notifyListeners();
    }
  }

  static Future<DeviceLocationResult> _geolocatorLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const DeviceLocationResult.failed(
        'Turn on location services to use your location',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return const DeviceLocationResult.failed('Location permission was not granted');
    }
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return DeviceLocationResult.ok(LatLng(pos.latitude, pos.longitude));
  }
}
