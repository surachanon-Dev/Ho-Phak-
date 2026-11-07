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
