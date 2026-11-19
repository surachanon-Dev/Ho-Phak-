int _toInt(dynamic v) => v is num ? v.toInt() : int.parse(v.toString());

/// รีวิวของหอพักที่แสดงให้เจ้าของ (อ่านอย่างเดียว เจ้าของตอบกลับไม่ได้)
class OwnerReview {
  OwnerReview({
    required this.id,
    required this.rating,
    required this.createdAt,
    this.body,
  });

  final int id;
  final int rating;
  final String? body;
  final String createdAt;

  factory OwnerReview.fromJson(Map<String, dynamic> json) => OwnerReview(
    id: _toInt(json['id']),
    rating: _toInt(json['rating']),
    body: json['body'] as String?,
    createdAt: json['created_at']?.toString() ?? '',
  );
}

/// รีวิวของนักศึกษาเอง จาก GET /api/reviews/me (ทุกสถานะ)
class MyReview {
  MyReview({
    required this.id,
    required this.dormitoryId,
    required this.dormitoryName,
    required this.rating,
    required this.status,
    required this.createdAt,
    this.body,
    this.moderationReason,
  });

  final int id;
  final int dormitoryId;
  final String dormitoryName;
  final int rating;
  final String? body;

  /// published | hidden
  final String status;

  /// เหตุผลจากแอดมินเมื่อถูกซ่อน
  final String? moderationReason;
  final String createdAt;

  bool get isPublished => status == 'published';
  bool get isHidden => status == 'hidden';

  factory MyReview.fromJson(Map<String, dynamic> json) => MyReview(
    id: _toInt(json['id']),
    dormitoryId: _toInt(json['dormitory_id']),
    dormitoryName: json['dormitory_name']?.toString() ?? '',
    rating: _toInt(json['rating']),
    body: json['body'] as String?,
    status: json['status']?.toString() ?? 'published',
    moderationReason: json['moderation_reason'] as String?,
    createdAt: json['created_at']?.toString() ?? '',
  );
}
