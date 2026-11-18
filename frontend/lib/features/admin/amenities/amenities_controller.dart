import 'package:flutter/foundation.dart';

import 'package:hopak_frontend/features/admin/services/admin_service.dart';
import 'package:hopak_frontend/core/network/api_client.dart';

/// สิ่งอำนวยความสะดวก 1 รายการ (ตาราง amenities)
@immutable
class AdminAmenity {
  const AdminAmenity({required this.id, required this.name});

  final int id;
  final String name;

  factory AdminAmenity.fromJson(Map<String, dynamic> json) =>
      AdminAmenity(id: (json['id'] as num).toInt(), name: json['name'] as String);
}

/// หน้า Amenities ของแอดมิน: รายการจาก backend และเพิ่ม/แก้ชื่อ/ลบ
/// ชื่อซ้ำ (ไม่สนตัวพิมพ์) ไม่ถูกส่งขึ้น server
class AdminAmenitiesController extends ChangeNotifier {
  AdminAmenitiesController(this._service);

  static const maxNameLength = 100;

  final AdminService _service;

  List<AdminAmenity> _items = const [];
  bool _loading = false;
  bool _busy = false;
  Object? _error;

  List<AdminAmenity> get items => _items;
  bool get loading => _loading;
  bool get busy => _busy;

  /// error ล่าสุด (โหลดหรือบันทึกไม่สำเร็จ) ให้หน้าจอแสดง
  Object? get error => _error;

  /// คืนข้อความ error ของชื่อ หรือ null ถ้าใช้ได้
  /// [exceptId] = id ของรายการที่กำลังแก้ (ไม่นับเป็นชื่อซ้ำกับตัวเอง)
  String? validateName(String name, {int? exceptId}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Please enter an amenity name.';
    if (trimmed.length > maxNameLength) {
      return 'Amenity name must be $maxNameLength characters or fewer.';
    }
    final normalized = trimmed.toLowerCase();
    final duplicate = _items.any(
      (a) => a.id != exceptId && a.name.trim().toLowerCase() == normalized,
    );
    return duplicate ? 'This amenity name already exists.' : null;
  }

  /// โหลดรายการ คืน true เมื่อสำเร็จ
  Future<bool> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final rows = await _service.amenities();
      _items = List.unmodifiable(rows.map(AdminAmenity.fromJson));
      return true;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// เพิ่มสิ่งอำนวยความสะดวก คืน true เมื่อสำเร็จ
  Future<bool> add(String name) => _write(name, null, () async {
    await _service.createAmenity(name.trim());
  });

  /// เปลี่ยนชื่อ คืน true เมื่อสำเร็จ
  Future<bool> rename(int id, String name) => _write(name, id, () async {
    await _service.renameAmenity(id, name.trim());
  });

  /// ลบ คืน true เมื่อสำเร็จ
  Future<bool> delete(int id) async {
    if (_busy) return false;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteAmenity(id);
    } catch (e) {
      _error = e;
      _busy = false;
      notifyListeners();
      return false;
    }
    _busy = false;
    await load();
    return true;
  }

  Future<bool> _write(String name, int? id, Future<void> Function() action) async {
    final problem = validateName(name, exceptId: id);
    if (problem != null) {
      _error = ApiException(400, problem);
      notifyListeners();
      return false;
    }
    if (_busy) return false;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      _error = e;
      _busy = false;
      notifyListeners();
      return false;
    }
    _busy = false;
    await load();
    return true;
  }
}
