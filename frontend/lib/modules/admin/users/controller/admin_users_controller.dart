import 'package:flutter/foundation.dart';

import '../../../../services/admin_service.dart';
import '../../../../core/network/api_client.dart';

/// หน้า Users ของแอดมิน: โหลดผู้ใช้ (กรองด้วย role/status) ระงับ และยกเลิกการระงับ
class AdminUsersController extends ChangeNotifier {
  AdminUsersController(this._service);

  /// ความยาวเหตุผลการระงับสูงสุด (ตรงกับกติกาในหน้าจอ)
  static const maxReasonLength = 300;

  final AdminService _service;

  List<Map<String, dynamic>> _users = const [];
  bool _loading = false;
  bool _busy = false;
  Object? _error;

  /// ผู้ใช้ทั้งหมดที่โหลดมาแล้ว (ข้อมูลดิบ ไม่มีรหัสผ่าน)
  List<Map<String, dynamic>> get users => _users;
  bool get loading => _loading;
  bool get busy => _busy;
  Object? get error => _error;

  /// โหลดผู้ใช้ตามตัวกรอง (ค่าว่าง = ทั้งหมด) คืน true เมื่อสำเร็จ
  Future<bool> load({String? role, String? status}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _users = List.unmodifiable(
        await _service.allUsers(role: role, status: status),
      );
      return true;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// ระงับผู้ใช้ (เหตุผลต้องไม่ว่างและไม่เกิน 300 ตัวอักษร) คืน true เมื่อสำเร็จ
  Future<bool> suspend(int userId, String reason) async {
    final problem = validateReason(reason);
    if (problem != null) {
      _error = ApiException(400, problem);
      notifyListeners();
      return false;
    }
    return _act(() => _service.suspendUser(userId, reason.trim()));
  }

  /// ยกเลิกการระงับ คืน true เมื่อสำเร็จ
  Future<bool> restore(int userId) => _act(() => _service.restoreUser(userId));

  Future<bool> _act(Future<void> Function() action) async {
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

  static String? validateReason(String reason) {
    final text = reason.trim();
    if (text.isEmpty) return 'Please enter a suspension reason';
    if (text.length > maxReasonLength)
      return 'The reason must be at most $maxReasonLength characters';
    return null;
  }

  /// บทบาทที่แสดง เช่น owner → Owner
  static String displayRole(String? role) {
    final r = role ?? '';
    if (r.isEmpty) return '-';
    return r[0].toUpperCase() + r.substring(1);
  }

  /// สถานะที่แสดง: active → Active, suspended → Suspended
  static String displayStatus(String? status) =>
      status == 'suspended' ? 'Suspended' : 'Active';
}
