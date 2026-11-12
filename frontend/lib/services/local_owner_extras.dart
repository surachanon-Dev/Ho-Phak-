import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'owner_extras.dart';

/// เก็บข้อมูลฟีเจอร์ที่ backend ยังไม่มีไว้ในเครื่อง (shared_preferences)
/// คีย์ผูกกับ user id เพื่อไม่ให้ปนกันระหว่างบัญชีที่ล็อกอินในเครื่องเดียวกัน
class LocalOwnerExtras implements OwnerExtras {
  LocalOwnerExtras({required this.userId});

  final int? Function() userId;

  @override
  bool get isLocal => true;

  String _key(String name) => 'owner_extras.${userId() ?? 0}.$name';

  Future<Map<String, dynamic>> _readMap(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(name));
    if (raw == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeMap(String name, Map<String, dynamic> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(name), jsonEncode(value));
  }

  // ---- Amenities ----
  @override
  Future<List<Amenity>> amenities() async => localAmenityCatalog;

  @override
  Future<List<int>> dormAmenityIds(int dormId, List<int> fromServer) async {
    final map = await _readMap('amenities');
    final saved = map['$dormId'];
    if (saved is List) return saved.map((e) => (e as num).toInt()).toList();
    return const [];
  }

  @override
  Future<void> saveDormAmenityIds(int dormId, List<int> ids) async {
    final map = await _readMap('amenities');
    map['$dormId'] = ids;
    await _writeMap('amenities', map);
  }

  @override
  List<int> amenityIdsForServer(List<int> chosen, List<int> existingOnServer) =>
      existingOnServer;

  // ---- ค่าน้ำ / ค่าไฟ ----
  @override
  Future<DormUtilities?> utilities(int dormId) async {
    final map = await _readMap('utilities');
    final v = map['$dormId'];
    return v is Map ? DormUtilities.fromJson(Map<String, dynamic>.from(v)) : null;
  }

  @override
  Future<void> saveUtilities(int dormId, DormUtilities value) async {
    final map = await _readMap('utilities');
    map['$dormId'] = value.toJson();
    await _writeMap('utilities', map);
  }

  // ---- ลบหอ ----
  @override
  Future<Set<int>> deletedDormIds() async {
    final map = await _readMap('deleted');
    final list = map['ids'];
    if (list is! List) return {};
    return list.map((e) => (e as num).toInt()).toSet();
  }

  @override
  Future<void> deleteDorm(int dormId) async {
    final ids = await deletedDormIds();
    ids.add(dormId);
    await _writeMap('deleted', {'ids': ids.toList()});
  }

  // ---- เอกสารกรรมสิทธิ์ ----
  @override
  Future<DormDocument?> dormDocument(int dormId) async {
    final map = await _readMap('documents');
    final v = map['$dormId'];
    return v is Map ? DormDocument.fromJson(Map<String, dynamic>.from(v)) : null;
  }

  @override
  Future<void> saveDormDocument(int dormId, DormDocument? doc) async {
    final map = await _readMap('documents');
    if (doc == null) {
      map.remove('$dormId');
    } else {
      map['$dormId'] = doc.toJson();
    }
    await _writeMap('documents', map);
  }

  // ---- Report รีวิว ----
  @override
  Future<Map<int, ReviewReport>> reports() async {
    final map = await _readMap('reports');
    return {
      for (final e in map.entries)
        int.parse(e.key): ReviewReport(
          reviewId: int.parse(e.key),
          reason: e.value as String,
        ),
    };
  }

  @override
  Future<void> reportReview(int reviewId, String reason) async {
    final map = await _readMap('reports');
    map['$reviewId'] = reason;
    await _writeMap('reports', map);
  }

  // ---- โปรไฟล์ ----
  @override
  Future<OwnerProfile> profile({String? fallbackName}) async {
    final map = await _readMap('profile');
    if (map.isNotEmpty) return OwnerProfile.fromJson(map);
    return OwnerProfile(firstName: fallbackName ?? '');
  }

  @override
  Future<OwnerProfile> saveProfile({
    required String firstName,
    required String surname,
    required String phone,
    String? password,
    String? photoBase64,
  }) async {
    final current = await profile();
    var live = current.phone;
    String? pending = current.pendingPhone;
    if (phone != current.phone) {
      if (current.phone.isEmpty) {
        // ยังไม่เคยมีเบอร์ในเครื่อง (API ยังไม่ส่งเบอร์มา) ตั้งค่าได้เลย
        live = phone;
      } else {
        if (password == null || password.isEmpty) {
          throw ApiException(400, 'Enter your password to change your phone number');
        }
        pending = phone;
      }
    } else {
      pending = null;
    }
    final next = OwnerProfile(
      firstName: firstName,
      surname: surname,
      phone: live,
      pendingPhone: pending,
      photoBase64: photoBase64 == null
          ? current.photoBase64
          : (photoBase64.isEmpty ? null : photoBase64),
    );
    await _writeMap('profile', next.toJson());
    return next;
  }

  @override
  Future<void> changePassword({
    required String current,
    required String next,
  }) async {
    // เครื่องนี้ไม่มีรหัสผ่านจริงให้ตรวจ — ตรวจรูปแบบอย่างเดียว ไม่เปลี่ยนที่ server
    if (next.length < 8) {
      throw ApiException(400, 'New password must be at least 8 characters');
    }
  }

  // ---- ตั้งค่าแจ้งเตือน ----
  @override
  Future<NotificationPrefs> notificationPrefs() async {
    final map = await _readMap('notification_prefs');
    return map.isEmpty
        ? const NotificationPrefs()
        : NotificationPrefs.fromJson(map);
  }

  @override
  Future<void> saveNotificationPrefs(NotificationPrefs prefs) =>
      _writeMap('notification_prefs', prefs.toJson());
}
