import 'package:flutter/foundation.dart';

import '../services/admin_service.dart';
import '../../../core/network/api_client.dart';
import '../moderation/admin_users_controller.dart';

/// หน้ารายละเอียดผู้ใช้ของแอดมิน: โหลดผู้ใช้ 1 คนพร้อมหอของเจ้าของ และระงับ/ยกเลิกการระงับ
class AdminUserDetailController extends ChangeNotifier {
  AdminUserDetailController(this._service, {required this.userId});

  final AdminService _service;
  final int userId;

  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _dorms = const [];
  bool _loading = false;
  bool _busy = false;
  bool _notFound = false;
  Object? _error;

  /// ข้อมูลดิบของผู้ใช้ (ไม่มีรหัสผ่าน) หรือ null ถ้ายังไม่โหลด/ไม่พบ
  Map<String, dynamic>? get user => _user;

  /// หอทั้งหมดของเจ้าของคนนี้ (ว่างถ้าไม่ใช่เจ้าของ)
  List<Map<String, dynamic>> get dorms => _dorms;
  bool get loading => _loading;
  bool get busy => _busy;
  bool get notFound => _notFound;
  Object? get error => _error;

  /// ชื่อที่แสดง: username ถ้ามี ไม่งั้นใช้ ชื่อ + นามสกุล ไม่งั้นใช้ "User #id"
  String get displayName {
    final name = realNameOf(_user);
    return name.isEmpty ? 'User #$userId' : name;
  }

  String get initials {
    final words = realNameOf(_user).split(' ').where((w) => w.isNotEmpty).toList();
    final result = words.take(2).map((w) => w[0].toUpperCase()).join();
    return result.isEmpty ? '?' : result;
  }

  /// ชื่อจริงจากแถวผู้ใช้: username ถ้ามี ไม่งั้นใช้ ชื่อ + นามสกุล ไม่มีคืนค่าว่าง
  static String realNameOf(Map<String, dynamic>? row) {
    final username = (row?['username'] as String?)?.trim() ?? '';
    if (username.isNotEmpty) return username;
    final first = (row?['first_name'] as String?)?.trim() ?? '';
    final surname = (row?['surname'] as String?)?.trim() ?? '';
    return [first, surname].where((p) => p.isNotEmpty).join(' ');
  }

  String get phone => (_user?['phone'] as String?) ?? '-';
  String get role => AdminUsersController.displayRole(_user?['role'] as String?);
  String get status => AdminUsersController.displayStatus(_user?['status'] as String?);
  bool get isAdmin => _user?['role'] == 'admin';
  bool get isOwner => _user?['role'] == 'owner';
  bool get isSuspended => _user?['status'] == 'suspended';
  bool get isVerified => _user?['is_verified'] == 1 || _user?['is_verified'] == true;
  String get joined => formatDate(_user?['created_at']);
  String? get suspendedAt =>
      _user?['suspended_at'] == null ? null : formatDate(_user?['suspended_at']);
  String? get suspensionReason => _user?['suspension_reason'] as String?;

  /// แอดมินระงับแอดมินด้วยกันไม่ได้ และระงับซ้ำไม่ได้
  bool get canSuspend => _user != null && !isAdmin && !isSuspended;

  /// โหลดผู้ใช้และหอของเจ้าของ คืน true เมื่อพบผู้ใช้
  Future<bool> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final users = await _service.allUsers();
      final match = users.where((u) => _idOf(u) == userId).toList();
      _user = match.isEmpty ? null : match.first;
      _notFound = _user == null;
      if (_user != null && isOwner) {
        final all = await _service.allDormitories();
        _dorms = all.where((d) => _ownerIdOf(d) == userId).toList();
      } else {
        _dorms = const [];
      }
      return _user != null;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// ระงับผู้ใช้ (เหตุผลต้องไม่ว่างและไม่เกิน 300 ตัวอักษร) คืน true เมื่อสำเร็จ
  Future<bool> suspend(String reason) async {
    final problem = AdminUsersController.validateReason(reason);
    if (problem != null) {
      _error = ApiException(400, problem);
      notifyListeners();
      return false;
    }
    return _act(() => _service.suspendUser(userId, reason.trim()));
  }

  /// ยกเลิกการระงับ คืน true เมื่อสำเร็จ
  Future<bool> restore() => _act(() => _service.restoreUser(userId));

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

  static int? _idOf(Map<String, dynamic> row) => (row['id'] as num?)?.toInt();

  static int? _ownerIdOf(Map<String, dynamic> row) =>
      (row['owner_id'] as num?)?.toInt();

  /// แปลงวันที่จาก API (ISO หรือ "yyyy-mm-dd hh:mm:ss") เป็น yyyy-mm-dd ตามเวลาท้องถิ่น
  static String formatDate(Object? value) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) return '-';
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return text;
    final local = parsed.toLocal();
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    return '${local.year}-$mm-$dd';
  }
}
