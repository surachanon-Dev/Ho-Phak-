import 'package:flutter/foundation.dart';

import '../services/admin_service.dart';

/// ตัวเลขบนหน้า Dashboard และ badge ของเมนูซ้ายของแอดมิน (ดึงจาก backend จริง)
class AdminDashboardController extends ChangeNotifier {
  AdminDashboardController(this._service);

  final AdminService _service;

  int _dormsAwaiting = 0;
  int _ownerRequests = 0;
  int _reportedReviews = 0;
  int _suspendedDorms = 0;
  bool _loading = false;
  Object? _error;

  /// หอใหม่ + ฉบับแก้ไขที่รอตรวจ
  int get dormsAwaitingCount => _dormsAwaiting;

  /// คำขอยืนยันตัวตนของเจ้าของที่รอตรวจ
  int get ownerRequestsCount => _ownerRequests;

  /// รีวิวที่รอการตรวจ (สถานะ pending)
  int get reportedReviewsCount => _reportedReviews;

  /// หอที่ถูกระงับ
  int get suspendedCount => _suspendedDorms;

  /// มีรายการค้างรอทำอยู่หรือไม่ (ใช้แสดงข้อความ "all caught up")
  bool get allCaughtUp =>
      _dormsAwaiting == 0 && _ownerRequests == 0 && _reportedReviews == 0;

  /// จำนวนรายการที่ต้องจัดการ (หอรอตรวจ + รีวิวรอตรวจ)
  int get totalWaiting => _dormsAwaiting + _reportedReviews;

  bool get loading => _loading;
  Object? get error => _error;

  /// โหลดตัวเลขทั้งหมด คืน true เมื่อสำเร็จ
  Future<bool> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait<Object>([
        _service.queue(),
        _service.reviews('pending'),
        _service.allDormitories(status: 'suspended'),
      ]);
      final queue = results[0] as AdminQueue;
      _dormsAwaiting = queue.newDormitories.length + queue.revisions.length;
      _ownerRequests = queue.verifications.length;
      _reportedReviews = (results[1] as List).length;
      _suspendedDorms = (results[2] as List).length;
      return true;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
