/// ฟีเจอร์ฝั่ง owner ที่ backend ยังไม่มี endpoint
/// (amenities, ค่าน้ำ/ไฟแบบ Included, ลบหอ, report รีวิว, โปรไฟล์/รหัสผ่าน, ตั้งค่าแจ้งเตือน, เอกสารกรรมสิทธิ์)
///
/// หน้าจอเรียกผ่าน [OwnerExtras] เท่านั้น มี 2 ตัวทำงานแทนกัน:
///  - `LocalOwnerExtras`  เก็บในเครื่อง (shared_preferences) ใช้อยู่ตอนนี้
///  - `ApiOwnerExtras`    เรียก endpoint ที่คาดไว้ (ยังไม่ได้ทดสอบกับ backend จริง)
/// สลับด้วยค่า `kLocalOwnerExtras` ใน `app_services.dart` ที่เดียว
/// สัญญา endpoint ทั้งหมดอยู่ใน vault: `Project/Spec - Owner extras API (รอเชื่อม backend).md`
library;

/// สิ่งอำนวยความสะดวก (ตาราง `amenities`)
class Amenity {
  const Amenity(this.id, this.name);

  final int id;
  final String name;

  factory Amenity.fromJson(Map<String, dynamic> json) =>
      Amenity((json['id'] as num).toInt(), json['name'] as String);
}

/// รายการตั้งต้นตาม Figma O-3 (ลำดับเดียวกับในเฟรม)
/// ⏳ id เป็นของ local เท่านั้น — ห้ามส่งขึ้น backend จนกว่าจะ seed ตารางตรงกัน
const List<Amenity> localAmenityCatalog = [
  Amenity(1, 'Wi-Fi'),
  Amenity(2, 'CCTV'),
  Amenity(3, 'Key card'),
  Amenity(4, 'Air conditioner'),
  Amenity(5, 'Fan'),
  Amenity(6, 'Parking'),
  Amenity(7, 'Washing machine'),
  Amenity(8, 'Elevator'),
  Amenity(9, 'Pets allowed'),
];

/// วิธีระบุค่าน้ำ/ค่าไฟ (D-143, D-152)
enum UtilityMode { setPrice, included, notSpecified }

class DormUtilities {
  const DormUtilities({
    this.water = UtilityMode.notSpecified,
    this.electricity = UtilityMode.notSpecified,
  });

  final UtilityMode water;
  final UtilityMode electricity;

  Map<String, dynamic> toJson() => {
    'water': water.name,
    'electricity': electricity.name,
  };

  factory DormUtilities.fromJson(Map<String, dynamic> json) => DormUtilities(
    water: _mode(json['water']),
    electricity: _mode(json['electricity']),
  );

  static UtilityMode _mode(dynamic v) => UtilityMode.values.firstWhere(
    (m) => m.name == v,
    orElse: () => UtilityMode.notSpecified,
  );
}

/// โหมดที่ใช้แสดง/แก้: มีอัตราจาก server → setPrice เสมอ
/// ไม่มีอัตรา → ใช้ที่ผู้ใช้เลือกไว้ (Included / Not specified), ไม่มี = Not specified
UtilityMode utilityModeFor({required double? rate, UtilityMode? saved}) {
  if (rate != null) return UtilityMode.setPrice;
  if (saved == null || saved == UtilityMode.setPrice) {
    return UtilityMode.notSpecified;
  }
  return saved;
}

/// เอกสารกรรมสิทธิ์ของหอ (ชื่อไฟล์ + ขนาด)
class DormDocument {
  const DormDocument({required this.name, required this.sizeBytes});

  final String name;
  final int sizeBytes;

  Map<String, dynamic> toJson() => {'name': name, 'size': sizeBytes};

  factory DormDocument.fromJson(Map<String, dynamic> json) => DormDocument(
    name: json['name'] as String,
    sizeBytes: (json['size'] as num).toInt(),
  );
}

/// การ report รีวิว: รอแอดมินตัดสิน
class ReviewReport {
  const ReviewReport({required this.reviewId, required this.reason});

  final int reviewId;
  final String reason;
}

class OwnerProfile {
  const OwnerProfile({
    this.firstName = '',
    this.surname = '',
    this.phone = '',
    this.pendingPhone,
    this.photoBase64,
  });

  final String firstName;
  final String surname;

  /// เบอร์ที่ใช้ล็อกอินอยู่
  final String phone;

  /// เบอร์ใหม่ที่รอแอดมินอนุมัติ (O-8a)
  final String? pendingPhone;

  /// รูปโปรไฟล์ (base64) — ฝั่ง API จริงจะเปลี่ยนเป็น URL ตอนเชื่อม
  final String? photoBase64;

  String get fullName => '$firstName $surname'.trim();

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'surname': surname,
    'phone': phone,
    'pending_phone': pendingPhone,
    'photo': photoBase64,
  };

  factory OwnerProfile.fromJson(Map<String, dynamic> json) => OwnerProfile(
    firstName: (json['first_name'] as String?) ?? '',
    surname: (json['surname'] as String?) ?? '',
    phone: (json['phone'] as String?) ?? '',
    pendingPhone: json['pending_phone'] as String?,
    photoBase64: json['photo'] as String?,
  );
}

class NotificationPrefs {
  const NotificationPrefs({
    this.messages = true,
    this.approvals = true,
    this.reviews = false,
  });

  final bool messages;
  final bool approvals;
  final bool reviews;

  NotificationPrefs copyWith({bool? messages, bool? approvals, bool? reviews}) =>
      NotificationPrefs(
        messages: messages ?? this.messages,
        approvals: approvals ?? this.approvals,
        reviews: reviews ?? this.reviews,
      );

  Map<String, dynamic> toJson() => {
    'messages': messages,
    'approvals': approvals,
    'reviews': reviews,
  };

  factory NotificationPrefs.fromJson(Map<String, dynamic> json) =>
      NotificationPrefs(
        messages: json['messages'] != false,
        approvals: json['approvals'] != false,
        reviews: json['reviews'] == true,
      );
}

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

  Future<void> changePassword({
    required String current,
    required String next,
  });

  // ---- ตั้งค่าแจ้งเตือน ----
  Future<NotificationPrefs> notificationPrefs();
  Future<void> saveNotificationPrefs(NotificationPrefs prefs);
}
