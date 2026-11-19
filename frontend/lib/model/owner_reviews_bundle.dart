import '../../../shared/models/review.dart';

/// รีวิวหนึ่งรายการพร้อมชื่อหอ (หน้า My reviews)
class OwnerReviewEntry {
  OwnerReviewEntry(this.dormName, this.review);
  final String dormName;
  final OwnerReview review;
}

/// รีวิวของทุกหอ + ชื่อหอทั้งหมด (ไว้ทำตัวกรอง)
class OwnerReviewsBundle {
  OwnerReviewsBundle(this.entries, this.dormNames);
  final List<OwnerReviewEntry> entries;
  final List<String> dormNames;

  /// กรองตามชื่อหอ (null = ทั้งหมด)
  List<OwnerReviewEntry> visible(String? dormName) => dormName == null
      ? entries
      : entries.where((e) => e.dormName == dormName).toList();

  /// คะแนนเฉลี่ยของรายการที่กรองแล้ว (null = ไม่มีรีวิว)
  static double? average(List<OwnerReviewEntry> list) {
    if (list.isEmpty) return null;
    return list.fold<int>(0, (s, e) => s + e.review.rating) / list.length;
  }
}
