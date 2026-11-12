import '../core/api_client.dart';
import '../mock/mock_db.dart';
import '../models/activity.dart';
import '../models/dormitory.dart';
import '../models/user.dart';

class AdminStats {
  final Map<String, int> usersByRole;
  final int suspendedUsers;
  final Map<String, int> dormsByStatus;
  final int totalReviews;
  final List<AdminLog> recentLogs;
  const AdminStats(this.usersByRole, this.suspendedUsers, this.dormsByStatus, this.totalReviews, this.recentLogs);
}

/// Admin module (MOCK). Every action writes admin_logs and notifies the affected user.
class AdminService {
  final _db = MockDb.instance;

  void _admin() => _db.requireRole('admin');

  Map<String, dynamic> _dorm(int id) => _db.dormById(id) ?? (throw ApiException(404, 'ไม่พบหอพัก'));

  String _reason(String? r) {
    final t = (r ?? '').trim();
    if (t.isEmpty) throw ApiException(400, 'กรุณาระบุเหตุผล');
    return t;
  }

  Future<AdminStats> stats() async {
    _admin();
    await MockDb.delay();
    Map<String, int> countBy(List<Map<String, dynamic>> rows, String key) {
      final m = <String, int>{};
      for (final r in rows) {
        m[r[key] as String] = (m[r[key]] ?? 0) + 1;
      }
      return m;
    }

    final logs = List<Map<String, dynamic>>.of(_db.adminLogs)..sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
    return AdminStats(
      countBy(_db.users, 'role'),
      _db.users.where((u) => u['status'] == 'suspended').length,
      countBy(_db.dormitories, 'status'),
      _db.reviews.length,
      logs.take(5).map(AdminLog.fromJson).toList(),
    );
  }

  // ---------------- dormitories ----------------
  Future<List<Dormitory>> dorms({String? status, String q = ''}) async {
    _admin();
    await MockDb.delay();
    final query = q.trim().toLowerCase();
    final list = _db.dormitories
        .where((d) => status == null || d['status'] == status)
        .map(_db.dormJson)
        .where((d) => query.isEmpty || '${d['name']} ${d['owner_name']}'.toLowerCase().contains(query))
        .toList()
      ..sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
    return list.map(Dormitory.fromJson).toList();
  }

  Future<Dormitory> dorm(int id) async {
    _admin();
    await MockDb.delay(150);
    return Dormitory.fromJson(_db.dormJson(_dorm(id)));
  }

  void _setDormStatus(Map<String, dynamic> d, String status, {String? statusReason, String? rejection}) {
    d
      ..['status'] = status
      ..['status_reason'] = statusReason
      ..['rejection_reason'] = rejection
      ..['status_changed_by'] = _db.currentUser['id']
      ..['status_changed_at'] = MockDb.now()
      ..['updated_at'] = MockDb.now();
  }

  /// pending → published
  Future<void> approveDorm(int id) async {
    _admin();
    final d = _dorm(id);
    if (d['status'] != 'pending' && d['status'] != 'rejected') throw ApiException(400, 'อนุมัติได้เฉพาะหอที่รอตรวจสอบ');
    await MockDb.delay(200);
    _setDormStatus(d, 'published');
    _db.log('dormitory.approve', 'dormitory', id);
    _db.notify(d['owner_id'] as int, 'dormitory_status', '${d['name']} ได้รับการอนุมัติแล้ว',
        body: 'หอพักของคุณแสดงให้นักศึกษาเห็นแล้ว', relatedType: 'dormitory', relatedId: id);
  }

  /// pending → rejected (rejection_reason)
  Future<void> rejectDorm(int id, String? reason) async {
    _admin();
    final r = _reason(reason);
    final d = _dorm(id);
    if (d['status'] != 'pending') throw ApiException(400, 'ปฏิเสธได้เฉพาะหอที่รอตรวจสอบ');
    await MockDb.delay(200);
    _setDormStatus(d, 'rejected', rejection: r);
    _db.log('dormitory.reject', 'dormitory', id, details: {'reason': r});
    _db.notify(d['owner_id'] as int, 'dormitory_rejected', '${d['name']} ไม่ผ่านการอนุมัติ',
        body: 'เหตุผล: $r', relatedType: 'dormitory', relatedId: id);
  }

  /// published / hidden → suspended (status_reason)
  Future<void> suspendDorm(int id, String? reason) async {
    _admin();
    final r = _reason(reason);
    final d = _dorm(id);
    if (!['published', 'hidden'].contains(d['status'])) throw ApiException(400, 'ระงับได้เฉพาะหอที่เคยเผยแพร่แล้ว');
    await MockDb.delay(200);
    _setDormStatus(d, 'suspended', statusReason: r);
    _db.log('dormitory.suspend', 'dormitory', id, details: {'reason': r});
    _db.notify(d['owner_id'] as int, 'dormitory_suspended', '${d['name']} ถูกระงับ',
        body: 'เหตุผล: $r', relatedType: 'dormitory', relatedId: id);
  }

  /// suspended → published
  Future<void> restoreDorm(int id) async {
    _admin();
    final d = _dorm(id);
    if (d['status'] != 'suspended') throw ApiException(400, 'หอพักนี้ไม่ได้ถูกระงับ');
    await MockDb.delay(200);
    _setDormStatus(d, 'published');
    _db.log('dormitory.restore', 'dormitory', id);
    _db.notify(d['owner_id'] as int, 'dormitory_restored', 'หอพักกลับมาแสดงแล้ว', body: d['name'] as String, relatedType: 'dormitory', relatedId: id);
  }

  // ---------------- users ----------------
  Future<List<AppUser>> users({String? role, String? status, String q = ''}) async {
    _admin();
    await MockDb.delay();
    final query = q.trim().toLowerCase();
    final list = _db.users
        .where((u) => role == null || u['role'] == role)
        .where((u) => status == null || u['status'] == status)
        .where((u) => query.isEmpty || '${u['username'] ?? ''} ${u['phone']}'.toLowerCase().contains(query))
        .toList()
      ..sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
    return list.map(AppUser.fromJson).toList();
  }

  Map<String, dynamic> _manageable(int id) {
    final u = _db.userById(id);
    if (u == null) throw ApiException(404, 'ไม่พบผู้ใช้');
    if (u['role'] == 'admin') throw ApiException(403, 'ไม่สามารถจัดการบัญชีผู้ดูแลระบบได้');
    return u;
  }

  Future<void> suspendUser(int id, String? reason) async {
    _admin();
    final why = _reason(reason);
    final u = _manageable(id);
    await MockDb.delay(200);
    u
      ..['status'] = 'suspended'
      ..['suspension_reason'] = why
      ..['suspended_at'] = MockDb.now()
      ..['suspended_by'] = _db.currentUser['id'];
    _db.log('user.suspend', 'user', id, details: {'reason': why});
  }

  Future<void> activateUser(int id) async {
    _admin();
    final u = _manageable(id);
    await MockDb.delay(200);
    u
      ..['status'] = 'active'
      ..['suspension_reason'] = null
      ..['suspended_at'] = null
      ..['suspended_by'] = null;
    _db.log('user.activate', 'user', id);
    _db.notify(id, 'account_restored', 'บัญชีของคุณกลับมาใช้งานได้แล้ว');
  }

  // ---------------- reviews (view only – no publish / hide) ----------------
  Future<List<Review>> reviews({String q = ''}) async {
    _admin();
    await MockDb.delay();
    final query = q.trim().toLowerCase();
    final list = _db.reviews
        .map(_db.reviewJson)
        .where((r) => query.isEmpty || '${r['dormitory_name']} ${r['user_name']} ${r['body'] ?? ''}'.toLowerCase().contains(query))
        .toList()
      ..sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
    return list.map(Review.fromJson).toList();
  }

  Future<List<AdminLog>> logs({String? targetType}) async {
    _admin();
    await MockDb.delay();
    final list = _db.adminLogs.where((l) => targetType == null || l['target_type'] == targetType).toList()
      ..sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
    return list.map(AdminLog.fromJson).toList();
  }
}
