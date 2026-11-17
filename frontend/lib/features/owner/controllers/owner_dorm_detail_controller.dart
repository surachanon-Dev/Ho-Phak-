import 'package:flutter/foundation.dart';

import '../../../shared/models/dormitory.dart';
import '../../../shared/models/review.dart';
import 'dormitory_controller.dart';
import '../services/owner_extras.dart';

/// หน้ารายละเอียดหอของเจ้าของ: โหลดข้อมูลหอ รีวิว amenities และค่าน้ำ-ไฟ
/// สลับการแสดงให้นักศึกษาเห็น และลบหอ
class OwnerDormDetailController extends ChangeNotifier {
  OwnerDormDetailController({required this.dormitoryId, required DormitoryController dorms})
    : _dorms = dorms;

  final int dormitoryId;
  final DormitoryController _dorms;

  Dormitory? _dorm;
  List<OwnerReview> _reviews = const [];
  List<Amenity> _amenities = const [];
  DormUtilities? _utilities;
  bool _loading = true;
  bool _busy = false;
  bool _changed = false;
  Object? _error;

  Dormitory? get dorm => _dorm;
  List<OwnerReview> get reviews => _reviews;
  List<Amenity> get amenities => _amenities;
  DormUtilities? get utilities => _utilities;
  bool get loading => _loading;

  /// กำลังทำงานที่ต้องกันการกดซ้ำ
  bool get busy => _busy;

  /// มีการเปลี่ยนแปลงข้อมูลในหน้านี้ (ให้หน้ารายการโหลดใหม่เมื่อกลับ)
  bool get changed => _changed;
  Object? get error => _error;

  /// คะแนนเฉลี่ยรีวิว (null ถ้าไม่มีรีวิว)
  double? get averageRating => _reviews.isEmpty
      ? null
      : _reviews.fold<int>(0, (s, r) => s + r.rating) / _reviews.length;

  /// รีวิวล่าสุด (รายการแรกที่ backend ส่งมา)
  OwnerReview? get latestReview => _reviews.isEmpty ? null : _reviews.first;

  /// โหลดข้อมูลทั้งหมด คืน true เมื่อสำเร็จ
  Future<bool> load() async {
    _loading = true;
    notifyListeners();
    try {
      final results = await Future.wait<Object>([
        _dorms.get(dormitoryId),
        _dorms.reviews(dormitoryId),
      ]);
      final dorm = results[0] as Dormitory;
      final extras = await _dorms.loadDetailExtras(dorm);
      _dorm = dorm;
      _reviews = results[1] as List<OwnerReview>;
      _amenities = extras.amenities;
      _utilities = extras.utilities;
      _error = null;
      return true;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// สลับการแสดงให้นักศึกษาเห็น (PATCH visibility) แล้วโหลดใหม่ คืน true เมื่อสำเร็จ
  Future<bool> toggleVisibility() async {
    if (_busy) return false;
    _busy = true;
    notifyListeners();
    try {
      await _dorms.toggleVisibility(dormitoryId);
      _changed = true;
      _error = null;
      _busy = false;
      notifyListeners();
      await load();
      return true;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// ลบหอ คืน true เมื่อสำเร็จ
  Future<bool> delete() async {
    final dorm = _dorm;
    if (dorm == null || _busy) return false;
    _busy = true;
    notifyListeners();
    try {
      await _dorms.delete(dorm.id);
      _changed = true;
      _error = null;
      return true;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// ตั้งค่าว่ามีการแก้ไขจากหน้าฟอร์ม แล้วโหลดข้อมูลใหม่
  Future<bool> reloadAfterEdit() async {
    _changed = true;
    return load();
  }
}
