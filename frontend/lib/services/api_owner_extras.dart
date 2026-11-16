import 'api_client.dart';
import 'owner_extras.dart';

/// ฝั่งเชื่อม backend จริง — endpoint ด้านล่าง "คาดไว้" ยังไม่มีใน backend
/// และยังไม่เคยทดสอบ (สัญญาเต็มอยู่ใน vault: Spec - Owner extras API)
/// เปิดใช้โดยตั้ง `kLocalOwnerExtras = false` ใน `app_services.dart`
class ApiOwnerExtras implements OwnerExtras {
  ApiOwnerExtras(this._api);

  final ApiClient _api;

  @override
  bool get isLocal => false;

  static const _owner = '/api/owner';

  List<Map<String, dynamic>> _list(dynamic data, String key) =>
      ((data as Map<String, dynamic>)[key] as List)
          .cast<Map<String, dynamic>>();

  // GET /api/amenities → { amenities: [{id, name}] }
  @override
  Future<List<Amenity>> amenities() async => _list(
    await _api.get('/api/amenities'),
    'amenities',
  ).map(Amenity.fromJson).toList();

  // id ที่เลือกมากับ GET /api/owner/dormitories/:id (amenity_ids) อยู่แล้ว
  @override
  Future<List<int>> dormAmenityIds(int dormId, List<int> fromServer) async =>
      fromServer;

  // บันทึกพร้อม PUT หอ (field amenity_ids) ไม่ต้องเรียกแยก
  @override
  Future<void> saveDormAmenityIds(int dormId, List<int> ids) async {}

  @override
  List<int> amenityIdsForServer(List<int> chosen, List<int> existingOnServer) =>
      chosen;

  // GET/PUT /api/owner/dormitories/:id/utilities { water, electricity }
  //   ค่า: set_price | included | not_specified (ใช้ชื่อ enum ฝั่งแอปไปก่อน)
  @override
  Future<DormUtilities?> utilities(int dormId) async {
    final data = await _api.get('$_owner/dormitories/$dormId/utilities');
    return DormUtilities.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<void> saveUtilities(int dormId, DormUtilities value) =>
      _api.put('$_owner/dormitories/$dormId/utilities', value.toJson());

  // DELETE /api/owner/dormitories/:id (ลบพร้อมรูปและรีวิว)
  @override
  Future<Set<int>> deletedDormIds() async => {};

  @override
  Future<void> deleteDorm(int dormId) =>
      _api.delete('$_owner/dormitories/$dormId');

  // GET/PUT/DELETE /api/owner/dormitories/:id/document (multipart, ช่อง "document")
  // ฝั่งแอปยังไม่มี bytes ของไฟล์ในสัญญานี้ → ต้องขยายตอนเชื่อมจริง
  @override
  Future<DormDocument?> dormDocument(int dormId) async => null;

  @override
  Future<void> saveDormDocument(int dormId, DormDocument? doc) async {}

  // GET /api/owner/review-reports → { reports: [{review_id, reason}] }
  // POST /api/owner/reviews/:id/report { reason }
  @override
  Future<Map<int, ReviewReport>> reports() async {
    final data = await _api.get('$_owner/review-reports');
    return {
      for (final r in _list(data, 'reports'))
        (r['review_id'] as num).toInt(): ReviewReport(
          reviewId: (r['review_id'] as num).toInt(),
          reason: r['reason'] as String,
        ),
    };
  }

  @override
  Future<void> reportReview(int reviewId, String reason) async {
    await _api.post('$_owner/reviews/$reviewId/report', {'reason': reason});
  }

  // GET /api/me/profile → { profile: {first_name, surname, phone, pending_phone} }
  // PUT /api/me/profile { first_name, surname, phone, password? }
  @override
  Future<OwnerProfile> profile({String? fallbackName}) async {
    final data = await _api.get('/api/me/profile') as Map<String, dynamic>;
    return OwnerProfile.fromJson(data['profile'] as Map<String, dynamic>);
  }

  @override
  Future<OwnerProfile> saveProfile({
    required String firstName,
    required String surname,
    required String phone,
    String? password,
    String? photoBase64,
  }) async {
    final data = await _api.put('/api/me/profile', {
      'first_name': firstName,
      'surname': surname,
      'phone': phone,
      if (password != null && password.isNotEmpty) 'password': password,
      'photo': ?photoBase64,
    }) as Map<String, dynamic>;
    return OwnerProfile.fromJson(data['profile'] as Map<String, dynamic>);
  }

  // PUT /api/me/password { current_password, new_password }
  @override
  Future<void> changePassword({
    required String current,
    required String next,
  }) async {
    await _api.put('/api/me/password', {
      'current_password': current,
      'new_password': next,
    });
  }

  // GET/PUT /api/me/notification-settings { messages, approvals, reviews }
  @override
  Future<NotificationPrefs> notificationPrefs() async {
    final data = await _api.get('/api/me/notification-settings');
    return NotificationPrefs.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<void> saveNotificationPrefs(NotificationPrefs prefs) =>
      _api.put('/api/me/notification-settings', prefs.toJson());
}
