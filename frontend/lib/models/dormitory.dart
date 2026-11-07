import '../config/api_config.dart';

/// zone ที่ backend รองรับ
const List<String> dormZones = ['หน้ามอ', 'หลังมอ', 'คชพลแลนด์'];

/// รูปแบบการคิดค่าน้ำ/ค่าไฟ
class BillingType {
  static const perUnit = 'per_unit';
  static const perPersonMonth = 'per_person_month';
  static const perRoomMonth = 'per_room_month';

  static const all = [perUnit, perPersonMonth, perRoomMonth];

  static String label(String type) => switch (type) {
    BillingType.perUnit => 'ตามหน่วยที่ใช้',
    BillingType.perPersonMonth => 'ต่อคนต่อเดือน',
    BillingType.perRoomMonth => 'ต่อห้องต่อเดือน',
    _ => type,
  };
}

/// สถานะหอพักจาก backend
/// pending / published / changes_pending / rejected / hidden / suspended
class DormStatus {
  static const pending = 'pending';
  static const published = 'published';
  static const changesPending = 'changes_pending';
  static const rejected = 'rejected';
  static const hidden = 'hidden';
  static const suspended = 'suspended';

  static String label(String status) => switch (status) {
    DormStatus.pending => 'รอตรวจสอบ',
    DormStatus.published => 'เผยแพร่แล้ว',
    DormStatus.changesPending => 'รอตรวจสอบการแก้ไข',
    DormStatus.rejected => 'ไม่ผ่านการตรวจสอบ',
    DormStatus.hidden => 'ซ่อนอยู่',
    DormStatus.suspended => 'ถูกระงับ',
    _ => status,
  };
}

double? _toDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

double _toDouble(dynamic v) => _toDoubleOrNull(v) ?? 0;

int _toInt(dynamic v) => v is num ? v.toInt() : int.parse(v.toString());

String? _toStr(dynamic v) => v?.toString();

class DormImage {
  DormImage({required this.id, required this.filePath, this.sortOrder = 0});

  final int id;
  final String filePath;
  final int sortOrder;

  String get fullUrl => ApiConfig.resolve(filePath);

  factory DormImage.fromJson(Map<String, dynamic> json) => DormImage(
    id: _toInt(json['id']),
    filePath: json['file_path'] as String,
    sortOrder: _toInt(json['sort_order'] ?? 0),
  );
}

class Dormitory {
  Dormitory({
    required this.id,
    required this.name,
    required this.zone,
    required this.latitude,
    required this.longitude,
    required this.pricePerMonth,
    required this.totalRooms,
    required this.availableRooms,
    required this.status,
    this.waterRate,
    this.waterBillingType,
    this.electricityRate,
    this.electricityBillingType,
    this.description,
    this.address,
    this.contactPhone,
    this.statusReason,
    this.ratingAvg,
    this.reviewCount,
    this.amenityIds = const [],
    this.images = const [],
  });

  final int id;
  final String name;
  final String zone;
  final double latitude;
  final double longitude;
  final int pricePerMonth;
  final int totalRooms;
  final int availableRooms;
  final String status;
  final double? waterRate;
  final String? waterBillingType;
  final double? electricityRate;
  final String? electricityBillingType;
  final String? description;
  final String? address;
  final String? contactPhone;

  /// เหตุผลจากแอดมินเมื่อถูกปฏิเสธ (จาก rejection_reason)
  final String? statusReason;

  /// ค่าเฉลี่ยรีวิวและจำนวนรีวิวที่เผยแพร่แล้ว (มีใน endpoint สาธารณะ)
  final double? ratingAvg;
  final int? reviewCount;
  final List<int> amenityIds;
  final List<DormImage> images;

  /// เปิด/ปิดการแสดงผลได้เฉพาะ published และ hidden (backend ตอบ 409 กรณีอื่น)
  bool get canToggleVisibility =>
      status == DormStatus.published || status == DormStatus.hidden;

  /// suspended แก้ไขไม่ได้ (backend ตอบ 403)
  bool get canEdit => status != DormStatus.suspended;

  /// MySQL DECIMAL มักถูกส่งมาเป็น string จึงต้องแปลงเอง
  factory Dormitory.fromJson(Map<String, dynamic> json) => Dormitory(
    id: _toInt(json['id']),
    name: json['name'] as String,
    zone: json['zone'] as String,
    latitude: _toDouble(json['latitude']),
    longitude: _toDouble(json['longitude']),
    pricePerMonth: _toInt(json['price_per_month']),
    totalRooms: _toInt(json['total_rooms'] ?? 0),
    availableRooms: _toInt(json['available_rooms'] ?? 0),
    status: (json['status'] as String?) ?? DormStatus.pending,
    waterRate: _toDoubleOrNull(json['water_rate']),
    waterBillingType: _toStr(json['water_billing_type']),
    electricityRate: _toDoubleOrNull(json['electricity_rate']),
    electricityBillingType: _toStr(json['electricity_billing_type']),
    description: _toStr(json['description']),
    address: _toStr(json['address']),
    contactPhone: _toStr(json['contact_phone']),
    statusReason: _toStr(json['rejection_reason']),
    ratingAvg: _toDoubleOrNull(json['rating_avg']),
    reviewCount: json['review_count'] == null
        ? null
        : _toInt(json['review_count']),
    amenityIds: ((json['amenity_ids'] as List?) ?? const [])
        .map(_toInt)
        .toList(),
    images: ((json['images'] as List?) ?? const [])
        .map((e) => DormImage.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

/// ข้อมูลที่ส่งตอน POST (เพิ่ม) และ PUT (แก้ไข ต้องส่งครบ)
class DormitoryInput {
  DormitoryInput({
    required this.name,
    required this.zone,
    required this.latitude,
    required this.longitude,
    required this.pricePerMonth,
    required this.totalRooms,
    required this.availableRooms,
    this.waterRate,
    this.waterBillingType,
    this.electricityRate,
    this.electricityBillingType,
    this.description,
    this.address,
    this.contactPhone,
    this.amenityIds = const [],
  });

  final String name;
  final String zone;
  final double latitude;
  final double longitude;
  final int pricePerMonth;
  final int totalRooms;
  final int availableRooms;
  final double? waterRate;
  final String? waterBillingType;
  final double? electricityRate;
  final String? electricityBillingType;
  final String? description;
  final String? address;
  final String? contactPhone;
  final List<int> amenityIds;

  /// rate กับ billing_type ต้องส่งคู่กัน หรือไม่ส่งทั้งคู่ จึงใส่เฉพาะเมื่อมี rate
  Map<String, dynamic> toJson() => {
    'name': name,
    'zone': zone,
    'latitude': latitude,
    'longitude': longitude,
    'price_per_month': pricePerMonth,
    'total_rooms': totalRooms,
    'available_rooms': availableRooms,
    if (waterRate != null) 'water_rate': waterRate,
    if (waterRate != null) 'water_billing_type': waterBillingType,
    if (electricityRate != null) 'electricity_rate': electricityRate,
    if (electricityRate != null)
      'electricity_billing_type': electricityBillingType,
    'description': description,
    'address': address,
    'contact_phone': contactPhone,
    'amenity_ids': amenityIds,
  };
}
