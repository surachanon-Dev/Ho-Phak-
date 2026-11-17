import 'package:flutter/foundation.dart';

import '../services/admin_service.dart';
import '../services/api_client.dart';

/// หน้า Dorms ของแอดมิน
/// - คิวรอตรวจ: หอใหม่ (pending) และฉบับแก้ไข (revisions) อนุมัติ/ปฏิเสธ
/// - หอทั้งหมด: กรองด้วยสถานะ ระงับ และยกเลิกการระงับ
class AdminDormsController extends ChangeNotifier {
  AdminDormsController(this._service);

  static const maxReasonLength = 300;

  final AdminService _service;

  List<Map<String, dynamic>> _newDormitories = const [];
  List<Map<String, dynamic>> _revisions = const [];
  List<Map<String, dynamic>> _allDormitories = const [];
  String? _statusFilter;
  bool _loading = false;
  bool _busy = false;
  Object? _error;

  List<Map<String, dynamic>> get newDormitories => _newDormitories;
  List<Map<String, dynamic>> get revisions => _revisions;
  List<Map<String, dynamic>> get allDormitories => _allDormitories;

  /// ตัวกรองสถานะของหอทั้งหมด (null = ทุกสถานะ)
  String? get statusFilter => _statusFilter;

  /// จำนวนรายการที่รอตรวจ (หอใหม่ + ฉบับแก้ไข)
  int get awaitingCount => _newDormitories.length + _revisions.length;

  bool get loading => _loading;
  bool get busy => _busy;
  Object? get error => _error;

  /// โหลดคิวรอตรวจ คืน true เมื่อสำเร็จ
  Future<bool> loadQueue() => _run(() async {
    final queue = await _service.queue();
    _newDormitories = List.unmodifiable(queue.newDormitories);
    _revisions = List.unmodifiable(queue.revisions);
  });

  /// โหลดหอทั้งหมดตามสถานะที่กรอง คืน true เมื่อสำเร็จ
  Future<bool> loadAll({String? status}) {
    _statusFilter = status;
    return _run(() async {
      _allDormitories = List.unmodifiable(await _service.allDormitories(status: status));
    });
  }

  /// โหลดทั้งคิวและหอทั้งหมดใหม่
  Future<bool> refreshAll() async {
    final q = await loadQueue();
    final a = await loadAll(status: _statusFilter);
    return q && a;
  }

  Future<bool> approve(int dormId) => _act(() => _service.approveDormitory(dormId));

  Future<bool> reject(int dormId, String reason) {
    final problem = validateReason(reason, 'เหตุผลการปฏิเสธ');
    if (problem != null) return _fail(problem);
    return _act(() => _service.rejectDormitory(dormId, reason.trim()));
  }

  Future<bool> suspend(int dormId, String reason) {
    final problem = validateReason(reason, 'เหตุผลการระงับ');
    if (problem != null) return _fail(problem);
    return _act(() => _service.suspendDormitory(dormId, reason.trim()));
  }

  Future<bool> restore(int dormId) => _act(() => _service.restoreDormitory(dormId));

  static String? validateReason(String reason, String label) {
    final text = reason.trim();
    if (text.isEmpty) return 'ต้องระบุ$label';
    if (text.length > maxReasonLength) return '$label ยาวเกิน $maxReasonLength ตัวอักษร';
    return null;
  }

  Future<bool> _fail(String message) async {
    _error = ApiException(400, message);
    notifyListeners();
    return false;
  }

  Future<bool> _run(Future<void> Function() load) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await load();
      return true;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

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
    await refreshAll();
    return true;
  }
}
