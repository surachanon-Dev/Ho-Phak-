import '../core/config/api_config.dart';

int _toInt(dynamic v) => v is num ? v.toInt() : int.parse(v.toString());

/// รายการโปรดจาก GET /api/favorites (ทุกสถานะ ให้แอปแสดง Unavailable เอง)
class Favorite {
  Favorite({
    required this.id,
    required this.name,
    required this.zone,
    required this.pricePerMonth,
    required this.status,
    required this.savedAt,
    this.coverImage,
  });

  final int id;
  final String name;
  final String zone;
  final int pricePerMonth;
  final String status;
  final String savedAt;

  /// path รูปแรกของหอ (cover_image) ถ้ามี
  final String? coverImage;

  String? get coverUrl => (coverImage == null || coverImage!.isEmpty)
      ? null
      : ApiConfig.resolve(coverImage!);

  /// หอที่ถูกซ่อนหรือระงับ นักศึกษาจะเห็นเป็น "ไม่พร้อมให้บริการ"
  bool get isAvailable => status == 'published';

  factory Favorite.fromJson(Map<String, dynamic> json) => Favorite(
    id: _toInt(json['id']),
    name: json['name'] as String,
    zone: json['zone'] as String,
    pricePerMonth: _toInt(json['price_per_month']),
    status: (json['status'] as String?) ?? '',
    savedAt: json['saved_at']?.toString() ?? '',
    coverImage: json['cover_image']?.toString(),
  );
}
