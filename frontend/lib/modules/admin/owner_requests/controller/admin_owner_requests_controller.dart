import 'package:flutter/foundation.dart';

import '../services/admin_service.dart';
import '../../../core/network/api_client.dart';

/// คำขอยืนยันตัวตนของเจ้าของ (แท็บ verification ของคิวตรวจ)
/// แท็บ: pending (รอตรวจ) / approved (อนุมัติแล้ว) / rejected (ไม่ผ่าน)
class AdminOwnerRequestsController extends ChangeNotifier {
  AdminOwnerRequestsController(this._service);

  /// ความยาวเหตุผลการปฏิเสธสูงสุด (ตรงกับกติกาในหน้าจอ)
  static const maxRejectReasonLength = 300;

  final AdminService _service;

  List<Map<String, dynamic>> _pending = const [];
  List<Map<String, dynamic>> _approved = const [];
  List<Map<String, dynamic>> _rejected = const [];
  bool _loading = false;
  bool _busy = false;
  Object? _error;

  /// รายการแต่ละแท็บ (ข้อมูลดิบจาก GET /api/admin/verifications)
  List<Map<String, dynamic>> get pending => _pending;
  List<Map<String, dynamic>> get approved => _approved;
  List<Map<String, dynamic>> get rejected => _rejected;

  /// จำนวนรอตรวจ (ใช้กับ badge ในเมนู)
  int get pendingCount => _pending.length;

  bool get loading => _loading;
  bool get busy => _busy;
  Object? get error => _error;

  /// โหลดทั้งสามแท็บพร้อมกัน คืน true เมื่อสำเร็จทั้งหมด
  Future<bool> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.verifications('pending'),
        _service.verifications('approved'),
        _service.verifications('rejected'),
      ]);
      _pending = List.unmodifiable(results[0]);
      _approved = List.unmodifiable(results[1]);
      _rejected = List.unmodifiable(results[2]);
      return true;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// อนุมัติคำขอ แล้วโหลดรายการใหม่ คืน true เมื่อสำเร็จ
  Future<bool> approve(int verificationId) =>
      _act(() => _service.approveVerification(verificationId));

  /// ปฏิเสธคำขอพร้อมเหตุผล (ต้องไม่ว่างและไม่เกิน 300 ตัวอักษร) คืน true เมื่อสำเร็จ
  Future<bool> reject(int verificationId, String reason) async {
    final problem = validateRejectReason(reason);
    if (problem != null) {
      _error = ApiException(400, problem);
      notifyListeners();
      return false;
    }
    return _act(
      () => _service.rejectVerification(verificationId, reason.trim()),
    );
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
    await load();
    return true;
  }

  /// คืนข้อความ error ของเหตุผลการปฏิเสธ หรือ null ถ้าใช้ได้
  static String? validateRejectReason(String reason) {
    final text = reason.trim();
    if (text.isEmpty) return 'ต้องระบุเหตุผลการปฏิเสธ';
    if (text.length > maxRejectReasonLength) {
      return 'เหตุผลยาวเกิน $maxRejectReasonLength ตัวอักษร';
    }
    return null;
  }

  /// ชื่อที่แสดง: "ชื่อ นามสกุล" หรือ username ถ้ายังไม่ได้ตั้งชื่อ
  static String displayName(Map<String, dynamic> row) {
    final first = (row['first_name'] as String?)?.trim() ?? '';
    final surname = (row['surname'] as String?)?.trim() ?? '';
    final full = '$first $surname'.trim();
    if (full.isNotEmpty) return full;
    return (row['owner_username'] as String?) ?? 'Owner #${row['owner_id']}';
  }
}
