import 'dart:typed_data';

import 'api_client.dart';

/// รายการที่รอตรวจจาก GET /api/admin/queue
/// เก็บเป็น Map ดิบ เพราะ field ของแต่ละรายการยังไม่ได้ทำเป็นโมเดล
class AdminQueue {
  AdminQueue({
    required this.newDormitories,
    required this.revisions,
    required this.verifications,
  });

  final List<Map<String, dynamic>> newDormitories;
  final List<Map<String, dynamic>> revisions;
  final List<Map<String, dynamic>> verifications;

  int get total =>
      newDormitories.length + revisions.length + verifications.length;
}

class AdminService {
  AdminService(this._api);

  final ApiClient _api;

  List<Map<String, dynamic>> _list(dynamic v) =>
      (v as List? ?? []).map((e) => e as Map<String, dynamic>).toList();

  /// GET /api/admin/queue
  Future<AdminQueue> queue() async {
    final data = await _api.get('/api/admin/queue') as Map<String, dynamic>;
    return AdminQueue(
      newDormitories: _list(data['new_dormitories']),
      revisions: _list(data['revisions']),
      verifications: _list(data['verifications']),
    );
  }

  /// POST /api/admin/dormitories/:id/approve (หอใหม่หรือฉบับแก้ไข)
  Future<void> approveDormitory(int id) =>
      _api.post('/api/admin/dormitories/$id/approve', const {});

  /// POST /api/admin/dormitories/:id/reject { reason } (ต้องมีเหตุผล)
  Future<void> rejectDormitory(int id, String reason) =>
      _api.post('/api/admin/dormitories/$id/reject', {'reason': reason});

  /// POST /api/admin/verifications/:id/approve
  Future<void> approveVerification(int id) =>
      _api.post('/api/admin/verifications/$id/approve', const {});

  /// POST /api/admin/verifications/:id/reject { reason }
  Future<void> rejectVerification(int id, String reason) =>
      _api.post('/api/admin/verifications/$id/reject', {'reason': reason});

  /// GET /api/admin/reviews?status=pending|published|hidden
  Future<List<Map<String, dynamic>>> reviews(String status) async {
    final data = await _api.get(
      '/api/admin/reviews?status=$status',
    ) as Map<String, dynamic>;
    return _list(data['reviews']);
  }

  /// POST /api/admin/reviews/:id/publish
  Future<void> publishReview(int id) =>
      _api.post('/api/admin/reviews/$id/publish', const {});

  /// POST /api/admin/reviews/:id/hide { reason }
  Future<void> hideReview(int id, String reason) =>
      _api.post('/api/admin/reviews/$id/hide', {'reason': reason});

  /// POST /api/admin/dormitories/:id/suspend { reason }
  Future<void> suspendDormitory(int id, String reason) =>
      _api.post('/api/admin/dormitories/$id/suspend', {'reason': reason});

  /// POST /api/admin/dormitories/:id/restore (ใช้ได้เฉพาะหอที่ถูกระงับ)
  Future<void> restoreDormitory(int id) =>
      _api.post('/api/admin/dormitories/$id/restore', const {});

  /// POST /api/admin/users/:id/suspend { reason } (ระงับ admin ไม่ได้)
  Future<void> suspendUser(int id, String reason) =>
      _api.post('/api/admin/users/$id/suspend', {'reason': reason});

  /// POST /api/admin/users/:id/restore
  Future<void> restoreUser(int id) =>
      _api.post('/api/admin/users/$id/restore', const {});

  /// GET /api/admin/verifications/:id/document → ไฟล์เอกสาร (ไม่เปิดสาธารณะ ต้องใช้ token แอดมิน)
  Future<Uint8List> verificationDocument(int id) =>
      _api.getBytes('/api/admin/verifications/$id/document');

  /// GET /api/admin/dormitories?status= → { dormitories: [...] }
  Future<List<Map<String, dynamic>>> allDormitories({String? status}) async {
    final qs = status == null ? '' : '?status=$status';
    final data =
        await _api.get('/api/admin/dormitories$qs') as Map<String, dynamic>;
    return _list(data['dormitories']);
  }

  /// GET /api/admin/users?role=&status= → { users: [...] } (ไม่มีรหัสผ่าน)
  Future<List<Map<String, dynamic>>> allUsers({
    String? role,
    String? status,
  }) async {
    final params = [
      if (role != null) 'role=$role',
      if (status != null) 'status=$status',
    ];
    final qs = params.isEmpty ? '' : '?${params.join('&')}';
    final data = await _api.get('/api/admin/users$qs') as Map<String, dynamic>;
    return _list(data['users']);
  }

  /// GET /api/admin/logs → 100 รายการล่าสุด
  Future<List<Map<String, dynamic>>> logs() async {
    final data = await _api.get('/api/admin/logs') as Map<String, dynamic>;
    return _list(data['logs']);
  }
}
