import 'package:flutter/foundation.dart';

import '../../models/favorite.dart';
import '../../services/favorite_service.dart';

/// รายการโปรดของนักศึกษา: โหลด นำออก และเก็บสถานะ
/// หอที่ซ่อนหรือระงับยังอยู่ในรายการ แต่ [Favorite.isAvailable] เป็น false
class FavoritesController extends ChangeNotifier {
  FavoritesController(this._favorites);

  final FavoriteService _favorites;

  List<Favorite> _items = const [];
  bool _loading = true;
  Object? _error;

  List<Favorite> get items => _items;
  bool get loading => _loading;
  Object? get error => _error;

  /// แสดงสปินเนอร์เต็มหน้าเฉพาะตอนที่ยังไม่มีข้อมูล
  bool get showFullLoader => _loading && _items.isEmpty;

  /// จำนวนหอที่ยังพร้อมให้บริการ
  int get availableCount => _items.where((f) => f.isAvailable).length;

  Future<bool> load() async {
    _loading = true;
    notifyListeners();
    try {
      _items = await _favorites.list();
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

  /// นำออกจากรายการโปรด เมื่อสำเร็จจะลบออกจากรายการในเครื่องทันที
  Future<bool> remove(int dormitoryId) async {
    try {
      await _favorites.remove(dormitoryId);
      _items = _items.where((f) => f.id != dormitoryId).toList();
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
