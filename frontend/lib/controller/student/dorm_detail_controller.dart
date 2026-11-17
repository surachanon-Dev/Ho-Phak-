import 'package:flutter/foundation.dart';

import '../../models/dormitory.dart';
import '../../models/favorite.dart';
import '../../models/review.dart';
import '../../services/chat_service.dart';
import '../../services/favorite_service.dart';
import '../../services/public_dormitory_service.dart';

/// รายละเอียดหอพักฝั่งนักศึกษา: ข้อมูลหอ รีวิว สถานะรายการโปรด
/// การเปิดแชท และการส่งรีวิว
class DormDetailController extends ChangeNotifier {
  DormDetailController({
    required this.dormitoryId,
    required this.myUserId,
    required PublicDormitoryService dorms,
    required FavoriteService favorites,
    required ChatService chats,
  }) : _dorms = dorms,
       _favorites = favorites,
       _chats = chats;

  final int dormitoryId;
  final int myUserId;
  final PublicDormitoryService _dorms;
  final FavoriteService _favorites;
  final ChatService _chats;

  Dormitory? _dorm;
  List<OwnerReview> _reviews = const [];
  bool _favorite = false;
  bool _loading = true;
  bool _busy = false;
  Object? _error;

  Dormitory? get dorm => _dorm;
  List<OwnerReview> get reviews => _reviews;
  bool get isFavorite => _favorite;
  bool get loading => _loading;

  /// true ระหว่างทำงานที่ต้องกันการกดซ้ำ (รายการโปรด แชท)
  bool get busy => _busy;
  Object? get error => _error;

  /// ค่าเฉลี่ยรีวิวจาก backend (null ถ้าไม่มีรีวิวที่เผยแพร่)
  double? get ratingAvg => _dorm?.ratingAvg;

  /// โหลดรายละเอียด รีวิว และสถานะรายการโปรดพร้อมกัน คืน true เมื่อสำเร็จทั้งหมด
  Future<bool> load() async {
    _loading = true;
    notifyListeners();
    try {
      final results = await Future.wait<Object>([
        _dorms.detail(dormitoryId),
        _dorms.reviews(dormitoryId),
        _favorites.list(),
      ]);
      _dorm = results[0] as Dormitory;
      _reviews = results[1] as List<OwnerReview>;
      final favs = results[2] as List<Favorite>;
      _favorite = favs.any((f) => f.id == dormitoryId);
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

  /// สลับสถานะรายการโปรด คืน true เมื่อสำเร็จ
  Future<bool> toggleFavorite() async {
    if (_busy) return false;
    _busy = true;
    notifyListeners();
    try {
      if (_favorite) {
        await _favorites.remove(dormitoryId);
      } else {
        await _favorites.add(dormitoryId);
      }
      _favorite = !_favorite;
      _error = null;
      return true;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// เปิดแชทกับเจ้าของ (backend คืนแชทเดิมถ้ามีแล้ว) คืน conversation id หรือ null เมื่อผิดพลาด
  Future<int?> openChat() async {
    if (_busy) return null;
    _busy = true;
    notifyListeners();
    try {
      final id = await _chats.open(dormitoryId);
      _error = null;
      return id;
    } catch (e) {
      _error = e;
      return null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// ส่งรีวิว (rating ต้องอยู่ 1–5) รอแอดมินตรวจก่อนแสดง คืน true เมื่อสำเร็จ
  Future<bool> submitReview({required int rating, String? body}) async {
    if (rating < 1 || rating > 5) {
      _error = ArgumentError.value(rating, 'rating', 'ต้องอยู่ระหว่าง 1–5');
      notifyListeners();
      return false;
    }
    final text = body?.trim();
    try {
      await _dorms.addReview(
        dormitoryId,
        rating,
        (text == null || text.isEmpty) ? null : text,
      );
      _error = null;
      return true;
    } catch (e) {
      _error = e;
      notifyListeners();
      return false;
    }
  }
}
