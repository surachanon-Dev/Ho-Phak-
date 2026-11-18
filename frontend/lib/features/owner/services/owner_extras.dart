/// ฟีเจอร์ฝั่ง owner ที่ backend ยังไม่มี endpoint
/// (amenities, ค่าน้ำ/ไฟแบบ Included, ลบหอ, report รีวิว, โปรไฟล์/รหัสผ่าน, ตั้งค่าแจ้งเตือน, เอกสารกรรมสิทธิ์)
///
/// หน้าจอเรียกผ่าน [OwnerExtras] เท่านั้น มี 2 ตัวทำงานแทนกัน:
///  - `LocalOwnerExtras`  เก็บในเครื่อง (shared_preferences) ใช้อยู่ตอนนี้
///  - `ApiOwnerExtras`    เรียก endpoint ที่คาดไว้ (ยังไม่ได้ทดสอบกับ backend จริง)
/// สลับด้วยค่า `kLocalOwnerExtras` ใน `app_services.dart` ที่เดียว
/// สัญญา endpoint ทั้งหมดอยู่ใน vault: `Project/Spec - Owner extras API (รอเชื่อม backend).md`
library;

import 'package:hopak_frontend/features/owner/models/amenity.dart';
import 'package:hopak_frontend/features/owner/models/dorm_document.dart';
import 'package:hopak_frontend/features/owner/models/dorm_utilities.dart';
import 'package:hopak_frontend/features/owner/models/notification_prefs.dart';
import 'package:hopak_frontend/features/owner/models/owner_profile.dart';
import 'package:hopak_frontend/features/owner/models/review_report.dart';

abstract class OwnerExtras {
  /// true = ข้อมูลเก็บในเครื่องเท่านั้น (หน้าจอใช้แสดงหมายเหตุ)
  bool get isLocal;

  // ---- Amenities ----
  Future<List<Amenity>> amenities();

  /// id ที่เลือกไว้ของหอ ([fromServer] = ค่าที่ API ส่งมา ใช้เมื่อเชื่อมจริง)
  Future<List<int>> dormAmenityIds(int dormId, List<int> fromServer);

  Future<void> saveDormAmenityIds(int dormId, List<int> ids);

  /// ค่าที่ส่งใน `amenity_ids` ของ POST/PUT หอ
  /// local: ส่งค่าเดิมของ server กลับไป (กันไม่ให้ id ปลอมไปชนตรวจสอบ)
  /// api: ส่งที่ผู้ใช้เลือก
  List<int> amenityIdsForServer(List<int> chosen, List<int> existingOnServer);

  // ---- ค่าน้ำ / ค่าไฟ ----
  Future<DormUtilities?> utilities(int dormId);
  Future<void> saveUtilities(int dormId, DormUtilities value);

  // ---- ลบหอ ----
  Future<Set<int>> deletedDormIds();
  Future<void> deleteDorm(int dormId);

  // ---- เอกสารกรรมสิทธิ์ ----
  Future<DormDocument?> dormDocument(int dormId);
  Future<void> saveDormDocument(int dormId, DormDocument? doc);

  // ---- Report รีวิว ----
  Future<Map<int, ReviewReport>> reports();
  Future<void> reportReview(int reviewId, String reason);

  // ---- โปรไฟล์ ----
  Future<OwnerProfile> profile({String? fallbackName});

  /// บันทึกชื่อ/นามสกุล/รูป (photoBase64: null = คงเดิม, '' = ลบ)
  /// ส่วนเบอร์ใหม่ต้องรอแอดมินอนุมัติและต้องใส่รหัสผ่าน
  Future<OwnerProfile> saveProfile({
    required String firstName,
    required String surname,
    required String phone,
    String? password,
    String? photoBase64,
  });

  Future<void> changePassword({required String current, required String next});

  // ---- ตั้งค่าแจ้งเตือน ----
  Future<NotificationPrefs> notificationPrefs();
  Future<void> saveNotificationPrefs(NotificationPrefs prefs);
}
