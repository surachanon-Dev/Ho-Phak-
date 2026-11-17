import '../../../core/network/api_client.dart';
import '../../../shared/models/dormitory.dart';
import '../../../shared/models/review.dart';
import '../models/dorm_detail_extras.dart';
import '../models/dorm_form_extras.dart';
import '../models/owner_reviews_bundle.dart';
import 'owner_extras.dart';
import '../models/dorm_utilities.dart';
import '../models/dorm_document.dart';
import '../models/review_report.dart';

class DormitoryService {
  DormitoryService(this._api, [this._extras]);

  final ApiClient _api;
  final OwnerExtras? _extras;

  static const _base = '/api/owner/dormitories';

  /// GET /api/owner/dormitories → { dormitories: [...] } ทุกสถานะของเจ้าของ
  /// ตัดหอที่ลบไว้ในเครื่องออก (โหมด local เท่านั้น — โหมด API คืนเซ็ตว่าง)
  Future<List<Dormitory>> list() async {
    final data = await _api.get(_base) as Map<String, dynamic>;
    final deleted = await _extras?.deletedDormIds() ?? <int>{};
    return (data['dormitories'] as List)
        .map((e) => Dormitory.fromJson(e as Map<String, dynamic>))
        .where((d) => !deleted.contains(d.id))
        .toList();
  }

  /// ลบหอพัก (ผ่าน OwnerExtras: local = ซ่อนในเครื่อง, api = DELETE)
  Future<void> delete(int id) => _extras!.deleteDorm(id);

  /// GET /api/owner/dormitories/:id → { dormitory: {...}, latest_revision }
  Future<Dormitory> get(int id) async {
    final data = await _api.get('$_base/$id') as Map<String, dynamic>;
    return Dormitory.fromJson(data['dormitory'] as Map<String, dynamic>);
  }

  /// POST /api/owner/dormitories → 201 { message, id } เข้าสถานะ pending
  Future<int> create(DormitoryInput input) async {
    final data = await _api.post(_base, input.toJson()) as Map<String, dynamic>;
    return (data['id'] as num).toInt();
  }

  /// PUT /api/owner/dormitories/:id ต้องส่งครบทุก field
  /// published/hidden → เก็บเป็นฉบับรอตรวจ (changes_pending ถ้าเผยแพร่อยู่)
  Future<void> update(int id, DormitoryInput input) =>
      _api.put('$_base/$id', input.toJson());

  /// PATCH /api/owner/dormitories/:id/visibility สลับ published ↔ hidden
  /// คืนสถานะใหม่จาก { status }
  Future<String> toggleVisibility(int id) async {
    final data = await _api.patch(
      '$_base/$id/visibility',
      const {},
    ) as Map<String, dynamic>;
    return data['status'] as String;
  }

  /// POST /api/owner/dormitories/:id/images (multipart, ช่อง "images" สูงสุด 5 ไฟล์)
  /// jpg, png, webp ไม่เกิน 5 MB ต่อไฟล์ รวมไม่เกิน 10 รูปต่อหอ
  Future<void> uploadImages(int dormId, List<UploadFile> files) => _api
      .uploadFiles('$_base/$dormId/images', fieldName: 'images', files: files);

  /// DELETE /api/owner/dormitories/:id/images/:imageId
  Future<void> deleteImage(int dormId, int imageId) =>
      _api.delete('$_base/$dormId/images/$imageId');

  /// โหลดข้อมูลที่ backend ยังไม่มี (amenities, โหมดค่าน้ำไฟ, เอกสาร) จาก OwnerExtras
  /// [d] = null เมื่อเพิ่มหอใหม่ (โหมดค่าน้ำไฟจึงเป็น null = ไม่ต้องเปลี่ยนค่าเดิมในฟอร์ม)
  Future<DormFormExtras> loadFormExtras(Dormitory? d) async {
    final extras = _extras;
    if (extras == null) return const DormFormExtras();
    final catalog = await extras.amenities();
    final ids = d == null
        ? <int>[]
        : await extras.dormAmenityIds(d.id, d.amenityIds);
    final util = d == null ? null : await extras.utilities(d.id);
    final doc = d == null ? null : await extras.dormDocument(d.id);
    return DormFormExtras(
      catalog: catalog,
      amenityIds: ids,
      document: doc,
      waterMode: d == null
          ? null
          : utilityModeFor(rate: d.waterRate, saved: util?.water),
      electricityMode: d == null
          ? null
          : utilityModeFor(rate: d.electricityRate, saved: util?.electricity),
    );
  }

  /// โหลดข้อมูลเสริมของหน้า detail จาก OwnerExtras
  Future<DormDetailExtras> loadDetailExtras(Dormitory dorm) async {
    final extras = _extras;
    if (extras == null) return const DormDetailExtras();
    final catalog = await extras.amenities();
    final ids = (await extras.dormAmenityIds(dorm.id, dorm.amenityIds)).toSet();
    final util = await extras.utilities(dorm.id);
    return DormDetailExtras(
      amenities: catalog.where((a) => ids.contains(a.id)).toList(),
      utilities: util,
    );
  }

  /// แปลงค่าในฟอร์ม (ข้อความ) เป็น DormitoryInput
  /// ส่งอัตราเฉพาะโหมด "Set price" (Included / Not specified = ไม่ส่ง)
  DormitoryInput buildInput({
    required String name,
    required String zone,
    required String latitude,
    required String longitude,
    required String price,
    required String totalRooms,
    required String availableRooms,
    required UtilityMode waterMode,
    required String waterRateText,
    required String? waterType,
    required UtilityMode electricityMode,
    required String electricityRateText,
    required String? electricityType,
    required String address,
    required String description,
    required String contactPhone,
    required Set<int> amenityIds,
    List<int> existingAmenityIds = const [],
  }) {
    final waterRate = waterMode == UtilityMode.setPrice
        ? _parseRate(waterRateText)
        : null;
    final electricityRate = electricityMode == UtilityMode.setPrice
        ? _parseRate(electricityRateText)
        : null;
    return DormitoryInput(
      name: name.trim(),
      zone: zone,
      latitude: double.parse(latitude.trim()),
      longitude: double.parse(longitude.trim()),
      pricePerMonth: int.parse(price.trim()),
      totalRooms: int.parse(totalRooms.trim()),
      availableRooms: int.parse(availableRooms.trim()),
      // rate กับ billing type ต้องคู่กัน จึงส่งเฉพาะเมื่อกรอกอัตรา
      waterRate: waterRate,
      waterBillingType: waterRate == null ? null : waterType,
      electricityRate: electricityRate,
      electricityBillingType: electricityRate == null ? null : electricityType,
      address: _optional(address),
      description: _optional(description),
      contactPhone: _optional(contactPhone),
      // local: ส่งค่าเดิมของ server กลับไป (id ของ local ไม่ตรงตาราง) / api: ส่งที่เลือก
      amenityIds:
          _extras?.amenityIdsForServer(
            amenityIds.toList(),
            existingAmenityIds,
          ) ??
          amenityIds.toList(),
    );
  }

  /// บันทึกหอ: [id] = null → สร้างใหม่, ไม่ null → แก้ไข แล้วบันทึกส่วนที่ backend
  /// ยังไม่มี (amenities, ค่าน้ำไฟ, เอกสาร) ผ่าน OwnerExtras คืน id ของหอ
  Future<int> save({
    int? id,
    required DormitoryInput input,
    required Set<int> amenityIds,
    required DormUtilities utilities,
    DormDocument? document,
  }) async {
    final int dormId;
    if (id != null) {
      dormId = id;
      await update(dormId, input);
    } else {
      dormId = await create(input);
    }
    final extras = _extras;
    if (extras != null) {
      await extras.saveDormAmenityIds(dormId, amenityIds.toList());
      await extras.saveUtilities(dormId, utilities);
      await extras.saveDormDocument(dormId, document);
    }
    return dormId;
  }

  static String? _optional(String text) {
    final t = text.trim();
    return t.isEmpty ? null : t;
  }

  static double? _parseRate(String text) {
    final t = text.trim();
    return t.isEmpty ? null : double.tryParse(t);
  }

  /// รวมรีวิวจากทุกหอของเจ้าของ (GET reviews ต่อหอ)
  Future<OwnerReviewsBundle> allReviews() async {
    final dorms = await list();
    final entries = <OwnerReviewEntry>[];
    for (final d in dorms) {
      final reviews = await this.reviews(d.id);
      entries.addAll(reviews.map((r) => OwnerReviewEntry(d.name, r)));
    }
    return OwnerReviewsBundle(entries, dorms.map((d) => d.name).toList());
  }

  /// รีวิวที่เจ้าของรายงานไว้แล้ว (review id → รายงาน)
  Future<Map<int, ReviewReport>> reviewReports() => _extras!.reports();

  /// รายงานรีวิวถึง admin พร้อมเหตุผล
  Future<void> reportReview(int reviewId, String reason) =>
      _extras!.reportReview(reviewId, reason);

  /// GET /api/owner/dormitories/:id/reviews → { reviews: [...] } เฉพาะที่เผยแพร่แล้ว
  Future<List<OwnerReview>> reviews(int id) async {
    final data = await _api.get('$_base/$id/reviews') as Map<String, dynamic>;
    return (data['reviews'] as List)
        .map((e) => OwnerReview.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
