import 'dart:math' as math;

import '../core/api_client.dart';
import '../core/config.dart';

/// In-memory fake database (MOCK MODE).
/// Every list below mirrors one table of the real `hopak` database (same column names),
/// and services build the same JSON the real API should return – so when the backend is ready,
/// only lib/services/ needs to change. Data resets every time the app restarts.
class MockDb {
  MockDb._() {
    _seed();
  }
  static final MockDb instance = MockDb._();

  /// Simulated network delay
  static Future<void> delay([int ms = 300]) => Future.delayed(Duration(milliseconds: ms));

  int? currentUserId;

  // ---------------- tables ----------------
  final users = <Map<String, dynamic>>[];
  final passwords = <int, String>{}; // users.password (mock keeps plain text; the real DB stores argon2id hashes)
  /// Forgot-password OTPs by phone (NEW table needed on the backend: password_resets)
  final passwordResets = <String, Map<String, dynamic>>{};
  final amenities = <Map<String, dynamic>>[];
  final dormitories = <Map<String, dynamic>>[];
  final dormitoryImages = <Map<String, dynamic>>[];
  final dormitoryAmenities = <Map<String, dynamic>>[];
  final favorites = <Map<String, dynamic>>[];
  final conversations = <Map<String, dynamic>>[];
  final messages = <Map<String, dynamic>>[];
  final notifications = <Map<String, dynamic>>[];
  final reviews = <Map<String, dynamic>>[];
  final adminLogs = <Map<String, dynamic>>[];

  final _ids = <String, int>{};
  int nextId(String table) => _ids[table] = (_ids[table] ?? 100) + 1;
  static String now() => DateTime.now().toIso8601String();

  // ---------------- lookups ----------------
  Map<String, dynamic>? userById(int? id) => users.where((u) => u['id'] == id).firstOrNull;
  Map<String, dynamic>? dormById(int? id) => dormitories.where((d) => d['id'] == id).firstOrNull;

  Map<String, dynamic> get currentUser {
    final u = userById(currentUserId);
    if (u == null) throw ApiException(401, 'กรุณาเข้าสู่ระบบ');
    if (u['status'] != 'active') throw ApiException(403, 'บัญชีนี้ถูกระงับ: ${u['suspension_reason'] ?? '-'}');
    return u;
  }

  Map<String, dynamic> requireRole(String role) {
    final u = currentUser;
    if (u['role'] != role) throw ApiException(403, 'ไม่มีสิทธิ์เข้าถึง');
    return u;
  }

  String nameOf(int? userId) {
    final u = userById(userId);
    if (u == null) return '-';
    final n = u['username']?.toString() ?? '';
    return n.isEmpty ? u['phone'].toString() : n;
  }

  static double haversine(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(lat2 - lat1), dLng = rad(lng2 - lng1);
    final a = math.pow(math.sin(dLat / 2), 2) + math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
    return 2 * r * math.asin(math.sqrt(a));
  }

  // ---------------- JSON builders (what the API would return) ----------------
  Map<String, dynamic> publicUser(Map<String, dynamic> u) => Map<String, dynamic>.from(u);

  List<Map<String, dynamic>> imagesOf(int dormId) =>
      dormitoryImages.where((i) => i['dormitory_id'] == dormId).toList()
        ..sort((a, b) => (a['sort_order'] as int).compareTo(b['sort_order'] as int));

  List<int> amenityIdsOf(int dormId) =>
      dormitoryAmenities.where((a) => a['dormitory_id'] == dormId).map((a) => a['amenity_id'] as int).toList();

  List<Map<String, dynamic>> publishedReviewsOf(int dormId) =>
      reviews.where((r) => r['dormitory_id'] == dormId && r['status'] == 'published').toList();

  Map<String, dynamic> dormJson(Map<String, dynamic> d) {
    final id = d['id'] as int;
    final owner = userById(d['owner_id'] as int);
    final rv = publishedReviewsOf(id);
    final avg = rv.isEmpty ? null : rv.map((r) => r['rating'] as int).reduce((a, b) => a + b) / rv.length;
    final ids = amenityIdsOf(id);
    return {
      ...d,
      'owner_name': nameOf(d['owner_id'] as int),
      'owner_phone': owner?['phone'],
      'images': imagesOf(id),
      'amenities': amenities.where((a) => ids.contains(a['id'])).toList(),
      'avg_rating': avg == null ? null : (avg * 10).round() / 10,
      'review_count': rv.length,
      'distance_meters': haversine(AppConfig.campusLat, AppConfig.campusLng, (d['latitude'] as num).toDouble(), (d['longitude'] as num).toDouble()).round(),
    };
  }

  Map<String, dynamic> reviewJson(Map<String, dynamic> r) => {
        ...r,
        'user_name': nameOf(r['user_id'] as int),
        'dormitory_name': dormById(r['dormitory_id'] as int)?['name'],
      };

  // ---------------- side effects used by many services ----------------
  void notify(int userId, String type, String title, {String? body, String? relatedType, int? relatedId}) {
    notifications.add({
      'id': nextId('notifications'),
      'user_id': userId,
      'type': type,
      'title': title,
      'body': body,
      'related_type': relatedType,
      'related_id': relatedId,
      'read_at': null,
      'created_at': now(),
    });
  }

  void log(String action, String targetType, int? targetId, {Map<String, dynamic>? details}) {
    final admin = currentUser;
    adminLogs.add({
      'id': nextId('admin_logs'),
      'admin_id': admin['id'],
      'admin_name': admin['username'],
      'action': action,
      'target_type': targetType,
      'target_id': targetId,
      'details': details,
      'created_at': now(),
    });
  }

  void setImages(int dormId, List<String> paths) {
    dormitoryImages.removeWhere((i) => i['dormitory_id'] == dormId);
    for (var i = 0; i < paths.length; i++) {
      dormitoryImages.add({'id': nextId('dormitory_images'), 'dormitory_id': dormId, 'file_path': paths[i], 'sort_order': i});
    }
  }

  void setAmenities(int dormId, List<int> ids) {
    dormitoryAmenities.removeWhere((a) => a['dormitory_id'] == dormId);
    for (final a in ids.toSet()) {
      dormitoryAmenities.add({'dormitory_id': dormId, 'amenity_id': a});
    }
  }

  // ---------------- seed data (based on the team's hopakDB.sql) ----------------
  void _seed() {
    final t0 = DateTime.now();
    String ago(int days, [int hours = 0]) => t0.subtract(Duration(days: days, hours: hours)).toIso8601String();

    Map<String, dynamic> user(int id, String? username, String phone, String role, {int verified = 0, String status = 'active', String? reason, int days = 30}) {
      final u = {
        'id': id,
        'username': username,
        'phone': phone,
        'role': role,
        'is_verified': verified,
        'status': status,
        'suspension_reason': reason,
        'suspended_at': status == 'suspended' ? ago(2) : null,
        'suspended_by': status == 'suspended' ? 10 : null,
        'created_at': ago(days),
        'updated_at': ago(days),
      };
      users.add(u);
      passwords[id] = 'Pass@1234';
      return u;
    }

    // 4 demo accounts (same as the buttons on the login screen)
    user(1, 'Bank', '0812345678', 'owner', days: 60); // owner – published dorms + chat with Frame
    user(2, 'Big', '0894565000', 'owner', days: 55); // owner – dorms in every other status (for testing admin)
    user(3, 'Frame', '0629546685', 'student', days: 50);
    user(10, 'admin', '0628540056', 'admin', days: 90);
    _ids['users'] = 10;

    for (final a in ['Wi-Fi', 'แอร์', 'ที่จอดรถ', 'เครื่องซักผ้า', 'กล้องวงจรปิด', 'คีย์การ์ด', 'ลิฟต์', 'ตู้เย็น', 'ร้านสะดวกซื้อ', 'เลี้ยงสัตว์ได้']) {
      amenities.add({'id': amenities.length + 1, 'name': a, 'created_at': ago(90), 'updated_at': ago(90)});
    }

    const lat = AppConfig.campusLat, lng = AppConfig.campusLng;
    void dorm(int id, int owner, String name, String zone, double dLat, double dLng, int price, String status,
        {num? water = 18, String? waterType = 'per_unit', num? elec = 7, String? elecType = 'per_unit', String? desc, String? address,
        String phone = '0811111111', String? statusReason, String? rejection, List<int> amen = const [1, 2], int img = 1, int days = 10}) {
      dormitories.add({
        'id': id,
        'owner_id': owner,
        'name': name,
        'zone': zone,
        'latitude': double.parse((lat + dLat).toStringAsFixed(6)),
        'longitude': double.parse((lng + dLng).toStringAsFixed(6)),
        'price_per_month': price,
        'water_rate': water,
        'water_billing_type': waterType,
        'electricity_rate': elec,
        'electricity_billing_type': elecType,
        'description': desc,
        'address': address,
        'contact_phone': phone,
        // NEW column: ownership document attached when the dorm is added (replaces account verification)
        'ownership_document_url': 'assets/images/demo-ownership.jpg',
        'status': status,
        'status_reason': statusReason,
        'status_changed_by': status == 'pending' ? null : 10,
        'status_changed_at': status == 'pending' ? null : ago(days - 1),
        'created_at': ago(days),
        'updated_at': ago(days),
        'rejection_reason': rejection,
      });
      final n = ((img - 1) % 4) + 1;
      setImages(id, ['assets/images/dorm-$n-exterior.jpg', 'assets/images/dorm-$n-room.jpg']);
      setAmenities(id, amen);
    }

    dorm(2, 1, 'หอพักแบงค์', 'หน้ามอ', 0.0030, 0.0015, 3500, 'published',
        desc: 'ห้องใหม่ สะอาด มี รปภ. 24 ชม. เดินถึงมหาวิทยาลัย 5 นาที', address: '12/3 ซอยหน้ามอ 2', phone: '0812345678',
        amen: [1, 2, 3, 5, 6], img: 1, days: 40);
    dorm(3, 1, 'คัมปาย เรสซิเดนซ์', 'หน้ามอ', 0.0018, -0.0022, 3000, 'published',
        desc: 'ใกล้ร้านอาหารและตลาดนัด', address: '45 ซอยหน้ามอ 5', phone: '0812345678', amen: [1, 2, 4], img: 2, days: 35);
    dorm(10, 1, 'BIG BUNK', 'คชพลแลนด์', 0.0042, 0.0035, 2800, 'published',
        water: 100, waterType: 'per_person_month', desc: 'ห้องกว้าง ราคาประหยัด มีลิฟต์', address: '465/654 หมู่บ้านคชพลแลนด์',
        phone: '0657896580', amen: [1, 3, 4, 7, 9], img: 3, days: 25);
    dorm(11, 2, 'บิ๊ก เพลส', 'หน้ามอ', -0.0019, 0.0011, 3500, 'published',
        desc: 'ห้องพัดลม/แอร์ ใกล้ประตูหน้ามอ', address: '88 ซอยหน้ามอ 1', phone: '0894565000', amen: [1, 2, 8], img: 4, days: 15);
    dorm(12, 2, 'บิ๊ก แมนชั่น', 'หลังมอ', -0.0034, -0.0016, 4000, 'pending',
        desc: 'หอใหม่ – รอผู้ดูแลระบบตรวจรูปและเอกสาร', address: '12 ซอยหลังมอ 3', phone: '0894565000', img: 1, days: 2);
    dorm(14, 2, 'บิ๊ก เฮ้าส์', 'คชพลแลนด์', 0.0060, -0.0010, 3000, 'rejected',
        rejection: 'รูปไม่ชัด และเอกสารไม่ตรงกับชื่อหอ', desc: 'บ้านเช่าแบ่งห้อง', address: '9 หมู่บ้านคชพลแลนด์', phone: '0894565000', img: 3, days: 6);
    dorm(15, 2, 'บิ๊ก เรสซิเดนซ์', 'หน้ามอ', 0.0011, 0.0040, 3800, 'hidden',
        desc: 'ห้องเต็ม – เจ้าของซ่อนไว้ชั่วคราว', address: '21 ซอยหน้ามอ 4', phone: '0894565000', img: 4, days: 12);
    dorm(16, 2, 'บิ๊ก คอนโด', 'หลังมอ', -0.0045, 0.0005, 3900, 'suspended',
        statusReason: 'ได้รับแจ้งว่าข้อมูลไม่ตรงกับความจริง', desc: 'คอนโดใกล้มหาวิทยาลัย', address: '5 ซอยหลังมอ 7', phone: '0894565000', img: 1, days: 11);
    _ids['dormitories'] = 16;

    void review(int id, int dormId, int userId, int rating, String? body, String status, {String? reason, int days = 5}) {
      reviews.add({
        'id': id,
        'dormitory_id': dormId,
        'user_id': userId,
        'rating': rating,
        'body': body,
        'status': status,
        'moderation_reason': reason,
        'moderated_by': null,
        'moderated_at': null,
        'created_at': ago(days),
        'updated_at': ago(days),
      });
    }

    // no moderation any more – every review is shown right away (status stays 'published')
    review(4, 2, 3, 5, 'ห้องสะอาด เจ้าของใจดี', 'published', days: 1);
    review(6, 10, 3, 3, 'ห้องกว้างดี แต่ไกลมหาวิทยาลัยนิดนึง', 'published', days: 6);
    review(9, 11, 3, 4, 'เดินไปเรียนสะดวก', 'published', days: 4);
    _ids['reviews'] = 9;

    favorites.add({'user_id': 3, 'dormitory_id': 3, 'created_at': ago(4)});

    conversations.add({'id': 3, 'tenant_id': 3, 'owner_id': 1, 'dormitory_id': 2, 'created_at': ago(2), 'deleted_by_tenant_at': null, 'deleted_by_owner_at': null});
    _ids['conversations'] = 3;
    messages.addAll([
      {'id': 5, 'conversation_id': 3, 'sender_id': 3, 'body': 'สวัสดีครับ ห้องแอร์ยังว่างไหมครับ', 'sent_at': ago(2), 'read_at': ago(2)},
      {'id': 6, 'conversation_id': 3, 'sender_id': 1, 'body': 'ว่างครับ เข้ามาดูห้องได้ทุกวัน 9 โมง – 6 โมงเย็น', 'sent_at': ago(1, 20), 'read_at': null},
    ]);
    _ids['messages'] = 6;

    void note(int id, int userId, String type, String title, String? body, String? relType, int? relId, {bool read = false, int days = 1}) {
      notifications.add({'id': id, 'user_id': userId, 'type': type, 'title': title, 'body': body, 'related_type': relType, 'related_id': relId, 'read_at': read ? ago(days) : null, 'created_at': ago(days)});
    }

    note(2, 1, 'dormitory_status', 'หอพักแบงค์ ได้รับการอนุมัติแล้ว', 'หอพักของคุณแสดงให้นักศึกษาเห็นแล้ว', 'dormitory', 2, read: true, days: 39);
    note(3, 2, 'dormitory_rejected', 'บิ๊ก เฮ้าส์ ไม่ผ่านการอนุมัติ', 'เหตุผล: รูปไม่ชัด และเอกสารไม่ตรงกับชื่อหอ', 'dormitory', 14, days: 5);
    note(4, 2, 'dormitory_suspended', 'บิ๊ก คอนโด ถูกระงับ', 'เหตุผล: ได้รับแจ้งว่าข้อมูลไม่ตรงกับความจริง', 'dormitory', 16, days: 3);
    _ids['notifications'] = 6;

    adminLogs.addAll([
      {'id': 8, 'admin_id': 10, 'admin_name': 'admin', 'action': 'dormitory.reject', 'target_type': 'dormitory', 'target_id': 14, 'details': {'reason': 'รูปไม่ชัด และเอกสารไม่ตรงกับชื่อหอ'}, 'created_at': ago(5)},
      {'id': 9, 'admin_id': 10, 'admin_name': 'admin', 'action': 'dormitory.suspend', 'target_type': 'dormitory', 'target_id': 16, 'details': {'reason': 'ได้รับแจ้งว่าข้อมูลไม่ตรงกับความจริง'}, 'created_at': ago(3)},
    ]);
    _ids['admin_logs'] = 11;
  }
}
