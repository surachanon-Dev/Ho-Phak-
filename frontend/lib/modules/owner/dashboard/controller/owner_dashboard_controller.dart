import 'package:flutter/foundation.dart';

import '../../../../model/dormitory.dart';
import '../../../../services/dormitory_service.dart';
import '../../../../model/dormitory_summary.dart';

/// หน้า Dashboard ของเจ้าของ: รายการหอทั้งหมดของเจ้าของ และสรุปสถานะ
class OwnerDashboardController extends ChangeNotifier {
  OwnerDashboardController(this._dorms);

  final DormitoryService _dorms;

  List<Dormitory> _items = const [];
  bool _loading = true;
  Object? _error;

  List<Dormitory> get items => _items;
  bool get loading => _loading;
  Object? get error => _error;

  /// แสดงสปินเนอร์เต็มหน้าเฉพาะตอนที่ยังไม่มีข้อมูล
  bool get showFullLoader => _loading && _items.isEmpty;

  /// สรุปจำนวนหอ/ห้องว่าง/สถานะ (ใช้กับการ์ดสถิติและแบนเนอร์)
  DormitorySummary get summary => DormitorySummary.of(_items);

  /// คืน true เมื่อโหลดสำเร็จ
  Future<bool> load() async {
    _loading = true;
    notifyListeners();
    try {
      _items = await _dorms.list();
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
}
