import 'package:flutter/foundation.dart';

import '../../../../core/utils/format.dart';
import '../../../../model/amenity.dart';
import '../../../../model/dormitory.dart';
import '../../../../services/public_dormitory_service.dart';

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
    this.amenityIds = const {},
  });

  final String query;
  final String? zone;
  final String minPriceText;
  final String maxPriceText;
  final bool roomsOnly;

  /// id สิ่งอำนวยความสะดวกที่เลือก (หอต้องมีครบทุกตัว)
  final Set<int> amenityIds;

  /// newest | price_asc | price_desc (backend เรียงให้) หรือ rating | distance (เรียงในแอป)
  final String sort;

  int? get minPrice => parsePriceInput(minPriceText);
  int? get maxPrice => parsePriceInput(maxPriceText);

  /// ข้อความแจ้งเตือนถ้าช่วงราคาใช้ไม่ได้ (ต่ำสุดมากกว่าสูงสุด) ไม่มีปัญหาคืน null
  String? get priceRangeError {
    final min = minPrice;
    final max = maxPrice;
    if (min != null && max != null && min > max) {
      return 'Minimum price must not be more than maximum price';
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
    Set<int>? amenityIds,
  }) => SearchFilters(
    query: query ?? this.query,
    zone: clearZone ? null : (zone ?? this.zone),
    minPriceText: minPriceText ?? this.minPriceText,
    maxPriceText: maxPriceText ?? this.maxPriceText,
    roomsOnly: roomsOnly ?? this.roomsOnly,
    sort: sort ?? this.sort,
    amenityIds: amenityIds ?? this.amenityIds,
  );
}

/// หน้าค้นหาหอพักฝั่งนักศึกษา: เก็บตัวกรอง เรียกค้นหา และจัดการสถานะ
class DormSearchController extends ChangeNotifier {
  DormSearchController(this._dorms);

  /// การเรียงที่ backend รองรับ (ส่งไปเป็น ?sort=)
  static const sortLabels = {
    'newest': 'Newest',
    'price_asc': 'Price: low to high',
    'price_desc': 'Price: high to low',
  };

  /// การเรียงที่ backend ยังไม่รองรับ แอปจึงเรียงผลลัพธ์เอง
  static const clientSortLabels = {
    'rating': 'Top rated',
    'distance': 'Closest to campus',
  };

  /// ตัวเลือกการเรียงทั้งหมดที่แสดงในหน้าจอ
  static const allSortLabels = {...sortLabels, ...clientSortLabels};

  final PublicDormitoryService _dorms;

  SearchFilters _filters = const SearchFilters();
  List<Dormitory> _items = const [];
  List<Amenity> _amenities = const [];
  bool _loading = false;
  Object? _error;
  String? _filterError;

  SearchFilters get filters => _filters;
  List<Dormitory> get items => _items;

  /// สิ่งอำนวยความสะดวกทั้งหมดให้เลือกในตัวกรอง (โหลดไม่ได้ = รายการว่าง ซ่อนส่วนนี้)
  List<Amenity> get amenities => _amenities;
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
      _filters.amenityIds.isNotEmpty ||
      _filters.sort != 'newest';

  void setQuery(String value) => _update(_filters.copyWith(query: value));

  void setMinPrice(String value) =>
      _update(_filters.copyWith(minPriceText: value));

  void setMaxPrice(String value) =>
      _update(_filters.copyWith(maxPriceText: value));

  /// null = ทุกโซน
  void setZone(String? zone) =>
      _update(_filters.copyWith(zone: zone, clearZone: zone == null));

  void setRoomsOnly(bool value) => _update(_filters.copyWith(roomsOnly: value));

  void setAmenities(Set<int> ids) =>
      _update(_filters.copyWith(amenityIds: Set.unmodifiable(ids)));

  /// โหลดรายการสิ่งอำนวยความสะดวกครั้งเดียว ถ้าโหลดไม่ได้ก็ไม่แสดงส่วนนี้ (ไม่ถือเป็น error ของหน้า)
  Future<void> loadAmenities() async {
    if (_amenities.isNotEmpty) return;
    try {
      _amenities = await _dorms.amenities();
      notifyListeners();
    } catch (_) {
      _amenities = const [];
    }
  }

  void setSort(String sort) {
    if (!allSortLabels.containsKey(sort)) return;
    _update(_filters.copyWith(sort: sort));
  }

  void _update(SearchFilters next) {
    _filters = next;
    notifyListeners();
  }

  /// ตั้งตัวกรองใหม่ทั้งหมดจากทางลัดในหน้าแรก (เลือกโซน / "ดูทั้งหมด") แล้วค้นหา
  Future<bool> applyQuick({String? zone, String? sort}) {
    _filters = SearchFilters(
      zone: zone,
      sort: allSortLabels.containsKey(sort) ? sort! : 'newest',
    );
    notifyListeners();
    return search();
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
      final sort = sortLabels.containsKey(_filters.sort) ? _filters.sort : 'newest';
      // ส่ง amenityIds เฉพาะตอนเลือก (รูปแบบการเรียกเดิมไม่เปลี่ยน)
      _items = _filters.amenityIds.isEmpty
          ? await _dorms.search(
              zone: _filters.zone,
              query: _filters.query,
              minPrice: _filters.minPrice,
              maxPrice: _filters.maxPrice,
              roomsOnly: _filters.roomsOnly,
              sort: sort,
            )
          : await _dorms.search(
              zone: _filters.zone,
              query: _filters.query,
              minPrice: _filters.minPrice,
              maxPrice: _filters.maxPrice,
              roomsOnly: _filters.roomsOnly,
              sort: sort,
              amenityIds: (_filters.amenityIds.toList()..sort()),
            );
      _items = sortLocally(_items, _filters.sort);
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

/// เรียงแบบที่ backend ยังไม่รองรับ: rating = คะแนนมากไปน้อย (ไม่มีรีวิวอยู่ท้าย),
/// distance = ใกล้มหาวิทยาลัยแม่ฟ้าหลวงก่อน; แบบอื่นคืนลำดับเดิม
List<Dormitory> sortLocally(List<Dormitory> items, String sort) {
  switch (sort) {
    case 'rating':
      return [...items]..sort((a, b) {
        final byRating = (b.ratingAvg ?? -1).compareTo(a.ratingAvg ?? -1);
        if (byRating != 0) return byRating;
        return (b.reviewCount ?? 0).compareTo(a.reviewCount ?? 0);
      });
    case 'distance':
      return [...items]..sort(
        (a, b) => metersFromMfu(
          a.latitude,
          a.longitude,
        ).compareTo(metersFromMfu(b.latitude, b.longitude)),
      );
    default:
      return items;
  }
}
