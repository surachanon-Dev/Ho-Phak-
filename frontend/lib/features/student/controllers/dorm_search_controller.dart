import 'package:flutter/foundation.dart';

import '../../../shared/models/dormitory.dart';
import '../services/public_dormitory_service.dart';

/// แปลงช่องราคาที่ผู้ใช้พิมพ์เป็นจำนวนเต็ม
/// ค่าว่าง ค่าที่ไม่ใช่ตัวเลข หรือค่าติดลบ คืน null (= ไม่กรองด้านนั้น)
int? parsePriceInput(String? raw) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty) return null;
  final value = int.tryParse(text);
  if (value == null || value < 0) return null;
  return value;
}

/// ตัวกรองและการเรียงลำดับของหน้าค้นหา (แยกออกจาก UI เพื่อทดสอบได้)
class SearchFilters {
  const SearchFilters({
    this.query = '',
    this.zone,
    this.minPriceText = '',
    this.maxPriceText = '',
    this.roomsOnly = false,
    this.sort = 'newest',
  });

  final String query;
  final String? zone;
  final String minPriceText;
  final String maxPriceText;
  final bool roomsOnly;

  /// newest | price_asc | price_desc
  final String sort;

  int? get minPrice => parsePriceInput(minPriceText);
  int? get maxPrice => parsePriceInput(maxPriceText);

  /// ข้อความแจ้งเตือนถ้าช่วงราคาใช้ไม่ได้ (ต่ำสุดมากกว่าสูงสุด) ไม่มีปัญหาคืน null
  String? get priceRangeError {
    final min = minPrice;
    final max = maxPrice;
    if (min != null && max != null && min > max) {
      return 'ราคาต่ำสุดต้องไม่มากกว่าราคาสูงสุด';
    }
    return null;
  }

  SearchFilters copyWith({
    String? query,
    String? zone,
    bool clearZone = false,
    String? minPriceText,
    String? maxPriceText,
    bool? roomsOnly,
    String? sort,
  }) => SearchFilters(
    query: query ?? this.query,
    zone: clearZone ? null : (zone ?? this.zone),
    minPriceText: minPriceText ?? this.minPriceText,
    maxPriceText: maxPriceText ?? this.maxPriceText,
    roomsOnly: roomsOnly ?? this.roomsOnly,
    sort: sort ?? this.sort,
  );
}

/// หน้าค้นหาหอพักฝั่งนักศึกษา: เก็บตัวกรอง เรียกค้นหา และจัดการสถานะ
class DormSearchController extends ChangeNotifier {
  DormSearchController(this._dorms);

  static const sortLabels = {
    'newest': 'ใหม่ล่าสุด',
    'price_asc': 'ราคาต่ำไปสูง',
    'price_desc': 'ราคาสูงไปต่ำ',
  };

  final PublicDormitoryService _dorms;

  SearchFilters _filters = const SearchFilters();
  List<Dormitory> _items = const [];
  bool _loading = false;
  Object? _error;
  String? _filterError;

  SearchFilters get filters => _filters;
  List<Dormitory> get items => _items;
  bool get loading => _loading;
  Object? get error => _error;

  /// ข้อความแจ้งเตือนตัวกรองที่ใช้ไม่ได้ (ถ้ามี) ทำให้ไม่ยิง request
  String? get filterError => _filterError;

  bool get hasActiveFilters =>
      _filters.query.trim().isNotEmpty ||
      _filters.zone != null ||
      _filters.minPriceText.trim().isNotEmpty ||
      _filters.maxPriceText.trim().isNotEmpty ||
      _filters.roomsOnly ||
      _filters.sort != 'newest';

  void setQuery(String value) => _update(_filters.copyWith(query: value));

  void setMinPrice(String value) =>
      _update(_filters.copyWith(minPriceText: value));

  void setMaxPrice(String value) =>
      _update(_filters.copyWith(maxPriceText: value));

  /// null = ทุกโซน
  void setZone(String? zone) => _update(
    _filters.copyWith(zone: zone, clearZone: zone == null),
  );

  void setRoomsOnly(bool value) => _update(_filters.copyWith(roomsOnly: value));

  void setSort(String sort) {
    if (!sortLabels.containsKey(sort)) return;
    _update(_filters.copyWith(sort: sort));
  }

  void _update(SearchFilters next) {
    _filters = next;
    notifyListeners();
  }

  /// ล้างตัวกรองทั้งหมดกลับค่าเริ่มต้น
  Future<bool> reset() {
    _filters = const SearchFilters();
    notifyListeners();
    return search();
  }

  /// ค้นหาด้วยตัวกรองปัจจุบัน คืน true เมื่อสำเร็จ
  Future<bool> search() async {
    _filterError = _filters.priceRangeError;
    if (_filterError != null) {
      notifyListeners();
      return false;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _dorms.search(
        zone: _filters.zone,
        query: _filters.query,
        minPrice: _filters.minPrice,
        maxPrice: _filters.maxPrice,
        roomsOnly: _filters.roomsOnly,
        sort: _filters.sort,
      );
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
