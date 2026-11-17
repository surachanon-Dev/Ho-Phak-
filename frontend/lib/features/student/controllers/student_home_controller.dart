import 'package:flutter/foundation.dart';

import '../../../shared/models/dormitory.dart';
import '../services/public_dormitory_service.dart';

/// หน้าแรกนักศึกษา: โหลดรายการหอพักที่เผยแพร่แล้ว (ไม่มีตัวกรอง)
///
/// ไม่แตะ UI: หน้าจออ่านค่าจาก getter แล้วเรียก [load] / [refresh]
class StudentHomeController extends ChangeNotifier {
  StudentHomeController(this._dorms);

  final PublicDormitoryService _dorms;

  List<Dormitory> _items = const [];
  bool _loading = true;
  Object? _error;

  /// หอพักที่เผยแพร่แล้ว เรียงตามที่ backend ส่งมา
  List<Dormitory> get items => _items;

  /// true ระหว่างโหลด
  bool get loading => _loading;

  /// error ล่าสุดจากการโหลด (null = ไม่มี error)
  Object? get error => _error;

  /// โหลดเสร็จแล้ว ไม่มี error และไม่มีหอ
  bool get isEmpty => !_loading && _error == null && _items.isEmpty;

  /// แสดงสถานะกำลังโหลดแบบเต็มหน้าเฉพาะตอนที่ยังไม่มีข้อมูล
  bool get showFullLoader => _loading && _items.isEmpty;

  /// โหลดรายการ คืน true เมื่อสำเร็จ
  Future<bool> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _dorms.search();
      return true;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// ดึงลงเพื่อรีเฟรช
  Future<bool> refresh() => load();
}
