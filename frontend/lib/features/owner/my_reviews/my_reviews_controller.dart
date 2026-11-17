import 'package:flutter/foundation.dart';

import 'package:hopak_frontend/features/owner/services/dormitory_service.dart';
import 'package:hopak_frontend/features/owner/models/review_report.dart';
import 'package:hopak_frontend/features/owner/models/owner_reviews_bundle.dart';

/// หน้ารีวิวของฉัน (อ่านอย่างเดียว + report): โหลดรีวิวทุกหอ กรองตามหอ และ report รีวิว
class MyReviewsController extends ChangeNotifier {
  MyReviewsController(this._dorms);

  /// เหตุผลการ report ยาวสุด (ตรงกับกติกาในหน้าจอ)
  static const maxReportReasonLength = 300;

  final DormitoryService _dorms;

  List<OwnerReviewEntry> _all = const [];
  List<String> _dormNames = const [];
  Map<int, ReviewReport> _reports = const {};
  String? _filter;
  bool _loading = true;
  Object? _error;

  bool get loading => _loading;
  Object? get error => _error;

  /// แสดงสปินเนอร์เต็มหน้าเฉพาะตอนที่ยังไม่มีข้อมูล
  bool get showFullLoader => _loading && _all.isEmpty;

  /// ชื่อหอทั้งหมดที่มีรีวิว
  List<String> get dormNames => _dormNames;

  /// ชื่อหอที่กรองอยู่ (null = ทุกหอ)
  String? get filter => _filter;

  /// รีวิวที่แสดงหลังกรอง
  List<OwnerReviewEntry> get visible =>
      OwnerReviewsBundle(_all, _dormNames).visible(_filter);

  /// ค่าเฉลี่ยของรีวิวที่แสดงอยู่ (null ถ้าไม่มี)
  double? get average => OwnerReviewsBundle.average(visible);

  /// รีวิวที่ report ไปแล้ว (key = review id)
  bool isReported(int reviewId) => _reports.containsKey(reviewId);

  void setFilter(String? dormName) {
    _filter = (dormName != null && _dormNames.contains(dormName))
        ? dormName
        : null;
    notifyListeners();
  }

  Future<bool> load() async {
    _loading = true;
    notifyListeners();
    try {
      final bundle = await _dorms.allReviews();
      final reports = await _dorms.reviewReports();
      _all = bundle.entries;
      _dormNames = bundle.dormNames;
      _reports = reports;
      _error = null;
      return true;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// report รีวิว: เหตุผลต้องไม่ว่างและไม่เกิน 300 ตัวอักษร คืน true เมื่อสำเร็จ
  Future<bool> report(int reviewId, String reason) async {
    final text = reason.trim();
    if (text.isEmpty || text.length > maxReportReasonLength) {
      _error = ArgumentError.value(
        reason,
        'reason',
        'เหตุผลต้องมี 1–$maxReportReasonLength ตัวอักษร',
      );
      notifyListeners();
      return false;
    }
    try {
      await _dorms.reportReview(reviewId, text);
      _reports = await _dorms.reviewReports();
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e;
      notifyListeners();
      return false;
    }
  }
}
