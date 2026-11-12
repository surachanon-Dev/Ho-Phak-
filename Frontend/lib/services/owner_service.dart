import '../core/api_client.dart';
import '../core/config.dart';
import '../mock/mock_db.dart';
import '../models/activity.dart';
import '../models/dormitory.dart';

/// Data from the owner's dorm form (columns of `dormitories` + amenity ids + image paths)
class DormForm {
  String name = '';
  String zone = AppConfig.zones.first;
  double? latitude;
  double? longitude;
  int? pricePerMonth;
  num? waterRate;
  String? waterBillingType = 'per_unit';
  num? electricityRate;
  String? electricityBillingType = 'per_unit';
  String description = '';
  String address = '';
  String contactPhone = '';
  Set<int> amenityIds = {};
  List<String> images = []; // file paths in display order (existing + newly picked) – at least 1 required
  String? ownershipDocument; // ownership document (deed / business licence …) – required

  static DormForm fromDorm(Dormitory d) => DormForm()
    ..name = d.name
    ..zone = d.zone
    ..latitude = d.latitude
    ..longitude = d.longitude
    ..pricePerMonth = d.pricePerMonth
    ..waterRate = d.waterRate
    ..waterBillingType = d.waterBillingType
    ..electricityRate = d.electricityRate
    ..electricityBillingType = d.electricityBillingType
    ..description = d.description ?? ''
    ..address = d.address ?? ''
    ..contactPhone = d.contactPhone ?? ''
    ..amenityIds = d.amenities.map((a) => a.id).toSet()
    ..images = d.images.map((i) => i.filePath).toList()
    ..ownershipDocument = d.ownershipDocumentUrl;

  /// Request body (same keys as the API / dormitories columns)
  Map<String, dynamic> toPayload() => {
        'name': name.trim(),
        'zone': zone,
        'latitude': latitude,
        'longitude': longitude,
        'price_per_month': pricePerMonth,
        'water_rate': waterRate,
        'water_billing_type': waterRate == null ? null : waterBillingType,
        'electricity_rate': electricityRate,
        'electricity_billing_type': electricityRate == null ? null : electricityBillingType,
        'description': description.trim().isEmpty ? null : description.trim(),
        'address': address.trim().isEmpty ? null : address.trim(),
        'contact_phone': contactPhone.trim().isEmpty ? null : contactPhone.trim(),
        'amenity_ids': amenityIds.toList(),
        'images': List<String>.of(images),
        'ownership_document_url': ownershipDocument,
      };
}

class OwnerStats {
  final Map<String, int> byStatus;
  final int unreadMessages;
  const OwnerStats(this.byStatus, this.unreadMessages);
  int get total => byStatus.values.fold(0, (a, b) => a + b);
  int count(String s) => byStatus[s] ?? 0;
}

/// Owner module (MOCK) – the rules the backend must also enforce
class OwnerService {
  final _db = MockDb.instance;

  Map<String, dynamic> get _me => _db.requireRole('owner');

  Map<String, dynamic> _owned(int id) {
    final d = _db.dormById(id);
    if (d == null || d['owner_id'] != _me['id']) throw ApiException(404, 'ไม่พบหอพัก');
    return d;
  }

  List<Map<String, dynamic>> get _mine => _db.dormitories.where((d) => d['owner_id'] == _me['id']).toList()
    ..sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));

  Future<OwnerStats> stats() async {
    await MockDb.delay(200);
    final mine = _mine;
    final by = <String, int>{};
    for (final d in mine) {
      by[d['status'] as String] = (by[d['status']] ?? 0) + 1;
    }
    final ids = mine.map((d) => d['id']).toSet();
    final myId = _me['id'];
    final convIds = _db.conversations.where((c) => c['owner_id'] == myId && c['deleted_by_owner_at'] == null).map((c) => c['id']).toSet();
    return OwnerStats(
      by,
      _db.messages.where((m) => convIds.contains(m['conversation_id']) && m['sender_id'] != myId && m['read_at'] == null).length,
    );
  }

  Future<List<Dormitory>> myDorms() async {
    await MockDb.delay(200);
    return _mine.map((d) => Dormitory.fromJson(_db.dormJson(d))).toList();
  }

  Future<Dormitory> get(int id) async {
    await MockDb.delay(150);
    return Dormitory.fromJson(_db.dormJson(_owned(id)));
  }

  void _validate(DormForm f) {
    if (f.name.trim().isEmpty) throw ApiException(400, 'กรุณากรอกชื่อหอพัก');
    if (!AppConfig.zones.contains(f.zone)) throw ApiException(400, 'โซนไม่ถูกต้อง');
    if (f.latitude == null || f.longitude == null) throw ApiException(400, 'กรุณาปักหมุดตำแหน่งหอพัก');
    if (f.pricePerMonth == null || f.pricePerMonth! <= 0) throw ApiException(400, 'ค่าเช่าต่อเดือนต้องมากกว่า 0');
    for (final t in [f.waterBillingType, f.electricityBillingType]) {
      if (t != null && !AppConfig.billingTypes.contains(t)) throw ApiException(400, 'รูปแบบการคิดค่าน้ำ/ค่าไฟไม่ถูกต้อง');
    }
    if ((f.waterRate ?? 0) < 0 || (f.electricityRate ?? 0) < 0) throw ApiException(400, 'ค่าน้ำ/ค่าไฟต้องไม่ติดลบ');
    if (f.images.isEmpty) throw ApiException(400, 'กรุณาแนบรูปหอพักอย่างน้อย 1 รูป');
    if ((f.ownershipDocument ?? '').isEmpty) throw ApiException(400, 'กรุณาแนบเอกสารแสดงความเป็นเจ้าของหอพัก');
    final phone = f.contactPhone.trim();
    if (phone.isNotEmpty && !RegExp(r'^[0-9+\-\s]{6,20}$').hasMatch(phone)) throw ApiException(400, 'เบอร์ติดต่อไม่ถูกต้อง');
  }

  void _apply(Map<String, dynamic> d, Map<String, dynamic> p) {
    for (final k in ['name', 'zone', 'latitude', 'longitude', 'price_per_month', 'water_rate',
        'water_billing_type', 'electricity_rate', 'electricity_billing_type', 'description', 'address', 'contact_phone', 'ownership_document_url']) {
      d[k] = p[k];
    }
    d['updated_at'] = MockDb.now();
    _db.setAmenities(d['id'] as int, List<int>.from(p['amenity_ids'] as List));
    _db.setImages(d['id'] as int, List<String>.from(p['images'] as List));
  }

  /// New dorm (with photos + ownership document) → pending until an admin approves it
  Future<Dormitory> create(DormForm f) async {
    final me = _me;
    _validate(f);
    await MockDb.delay(500);
    final id = _db.nextId('dormitories');
    final d = <String, dynamic>{
      'id': id,
      'owner_id': me['id'],
      'status': 'pending',
      'status_reason': null,
      'status_changed_by': null,
      'status_changed_at': null,
      'created_at': MockDb.now(),
      'rejection_reason': null,
    };
    _db.dormitories.add(d);
    _apply(d, f.toPayload());
    return Dormitory.fromJson(_db.dormJson(d));
  }

  /// Owner edits are saved right away (no admin approval of edits).
  /// pending / published / hidden keep their status · rejected → pending (sent for review again) · suspended → not allowed
  Future<String> update(int id, DormForm f) async {
    final d = _owned(id);
    _validate(f);
    await MockDb.delay(500);
    final status = d['status'] as String;
    if (status == 'suspended') throw ApiException(403, 'หอพักนี้ถูกระงับโดยผู้ดูแลระบบ แก้ไขไม่ได้');
    _apply(d, f.toPayload());
    if (status == 'rejected') {
      d
        ..['status'] = 'pending'
        ..['rejection_reason'] = null;
      return 'บันทึกแล้ว – ส่งให้ผู้ดูแลระบบตรวจสอบอีกครั้ง';
    }
    return 'บันทึกการแก้ไขแล้ว';
  }

  /// published ↔ hidden (owner can take the listing down temporarily)
  Future<void> setHidden(int id, bool hidden) async {
    final d = _owned(id);
    await MockDb.delay(200);
    if (hidden && d['status'] != 'published') throw ApiException(400, 'ซ่อนได้เฉพาะหอที่เผยแพร่อยู่');
    if (!hidden && d['status'] != 'hidden') throw ApiException(400, 'หอพักนี้ไม่ได้ถูกซ่อน');
    d
      ..['status'] = hidden ? 'hidden' : 'published'
      ..['updated_at'] = MockDb.now();
  }

  Future<void> delete(int id) async {
    _owned(id);
    await MockDb.delay(300);
    _db.dormitories.removeWhere((d) => d['id'] == id);
    _db.dormitoryImages.removeWhere((x) => x['dormitory_id'] == id);
    _db.dormitoryAmenities.removeWhere((x) => x['dormitory_id'] == id);
    _db.reviews.removeWhere((x) => x['dormitory_id'] == id);
    _db.favorites.removeWhere((x) => x['dormitory_id'] == id);
    for (final c in _db.conversations.where((c) => c['dormitory_id'] == id)) {
      c['dormitory_id'] = null; // ON DELETE SET NULL
    }
  }

  /// Published reviews of all my dorms (read-only for owners)
  Future<List<Review>> reviewsOfMyDorms() async {
    await MockDb.delay(200);
    final ids = _mine.map((d) => d['id']).toSet();
    final list = _db.reviews.where((r) => ids.contains(r['dormitory_id']) && r['status'] == 'published').map(_db.reviewJson).toList()
      ..sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
    return list.map(Review.fromJson).toList();
  }
}
