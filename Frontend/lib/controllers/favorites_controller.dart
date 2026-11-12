import 'package:flutter/foundation.dart';

import '../services/dorm_service.dart';

/// favorites table for the logged-in student
class FavoritesController extends ChangeNotifier {
  FavoritesController(this._service);
  final DormService _service;

  Set<int> ids = {};

  Future<void> load() async {
    try {
      ids = await _service.favoriteIds();
    } catch (_) {
      ids = {};
    }
    notifyListeners();
  }

  bool isFavorite(int dormId) => ids.contains(dormId);

  Future<void> toggle(int dormId) async {
    final on = await _service.toggleFavorite(dormId);
    on ? ids.add(dormId) : ids.remove(dormId);
    notifyListeners();
  }
}
