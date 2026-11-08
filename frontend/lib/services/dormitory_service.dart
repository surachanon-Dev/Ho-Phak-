import '../models/dormitory.dart';
import '../models/review.dart';
import 'api_client.dart';

class DormitoryService {
  DormitoryService(this._api);

  final ApiClient _api;

  static const _base = '/api/owner/dormitories';

  /// GET /api/owner/dormitories → { dormitories: [...] } ทุกสถานะของเจ้าของ
  Future<List<Dormitory>> list() async {
    final data = await _api.get(_base) as Map<String, dynamic>;
    return (data['dormitories'] as List)
        .map((e) => Dormitory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

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

  /// GET /api/owner/dormitories/:id/reviews → { reviews: [...] } เฉพาะที่เผยแพร่แล้ว
  Future<List<OwnerReview>> reviews(int id) async {
    final data = await _api.get('$_base/$id/reviews') as Map<String, dynamic>;
    return (data['reviews'] as List)
        .map((e) => OwnerReview.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
