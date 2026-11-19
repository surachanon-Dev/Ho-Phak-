import 'package:flutter/foundation.dart';

import '../../../../model/review.dart';
import '../../../../services/public_dormitory_service.dart';

/// หน้า "My reviews" ของนักศึกษา: โหลดรีวิวของฉัน แก้ไข และลบ
/// รีวิวขึ้นทันที แก้ไขแล้วยังแสดงอยู่ (admin ซ่อนได้เมื่อ owner รายงาน)
class MyReviewsController extends ChangeNotifier {
  MyReviewsController(this._dorms);

  final PublicDormitoryService _dorms;

  List<MyReview> _items = const [];
  bool _loading = true;
  Object? _error;

  List<MyReview> get items => _items;
  bool get loading => _loading;
  Object? get error => _error;

  /// แสดงสปินเนอร์เต็มหน้าเฉพาะตอนที่ยังไม่มีข้อมูล
  bool get showFullLoader => _loading && _items.isEmpty;

  Future<bool> load() async {
    _loading = true;
    notifyListeners();
    try {
      _items = await _dorms.myReviews();
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

  /// แก้ไขรีวิว (rating 1–5) สำเร็จแล้วโหลดรายการใหม่ คืน true เมื่อสำเร็จ
  Future<bool> update(int reviewId, {required int rating, String? body}) async {
    if (rating < 1 || rating > 5) {
      _error = ArgumentError.value(rating, 'rating', 'must be 1–5');
      notifyListeners();
      return false;
    }
    final text = body?.trim();
    try {
      await _dorms.updateReview(
        reviewId,
        rating,
        (text == null || text.isEmpty) ? null : text,
      );
      _error = null;
    } catch (e) {
      _error = e;
      notifyListeners();
      return false;
    }
    await load();
    return true;
  }

  /// ลบรีวิว เมื่อสำเร็จจะเอาออกจากรายการทันที
  Future<bool> remove(int reviewId) async {
    try {
      await _dorms.deleteReview(reviewId);
      _items = _items.where((r) => r.id != reviewId).toList();
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
