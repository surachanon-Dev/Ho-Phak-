import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'package:hopak_frontend/shared/models/dormitory.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:hopak_frontend/features/owner/services/dormitory_service.dart';
import 'package:hopak_frontend/features/owner/validation/dormitory_rules.dart';
import 'package:hopak_frontend/features/owner/models/amenity.dart';
import 'package:hopak_frontend/features/owner/models/dorm_utilities.dart';
import 'package:hopak_frontend/features/owner/models/dorm_document.dart';

/// ผลการบันทึกฟอร์มหอ
class DormSaveResult {
  const DormSaveResult({required this.dormId, this.photoError});

  final int dormId;

  /// บันทึกหอสำเร็จแต่อัปโหลดรูปไม่สำเร็จ (ข้อความสำหรับแสดงให้ผู้ใช้)
  final String? photoError;
}

/// ฟอร์มเพิ่ม/แก้ไขหอพัก: เก็บค่าที่กรอก ตรวจกติกา โหลดข้อมูลเสริม และบันทึก
/// ทุกการบันทึกเข้าสถานะรอแอดมินตรวจ
class OwnerDormFormController extends ChangeNotifier {
  OwnerDormFormController({required this.existing, required DormitoryService dorms})
    : _dorms = dorms,
      _name = existing?.name ?? '',
      _address = existing?.address ?? '',
      _price = existing?.pricePerMonth.toString() ?? '',
      _totalRooms = existing?.totalRooms.toString() ?? '',
      _availableRooms = existing?.availableRooms.toString() ?? '',
      _waterRate = _fmt(existing?.waterRate),
      _electricityRate = _fmt(existing?.electricityRate),
      _description = existing?.description ?? '',
      _contactPhone = existing?.contactPhone ?? '',
      _lat = existing?.latitude.toString() ?? '',
      _lng = existing?.longitude.toString() ?? '',
      _zone = existing?.zone ?? dormZones.first,
      _waterType = existing?.waterBillingType,
      _electricityType = existing?.electricityBillingType,
      _waterMode = utilityModeFor(rate: existing?.waterRate),
      _electricityMode = utilityModeFor(rate: existing?.electricityRate),
      _images = List.of(existing?.images ?? const []);

  final Dormitory? existing;
  final DormitoryService _dorms;

  String _name;
  String _address;
  String _price;
  String _totalRooms;
  String _availableRooms;
  String _waterRate;
  String _electricityRate;
  String _description;
  String _contactPhone;
  String _lat;
  String _lng;
  String _zone;
  String? _waterType;
  String? _electricityType;
  UtilityMode _waterMode;
  UtilityMode _electricityMode;
  List<Amenity> _catalog = const [];
  Set<int> _amenityIds = {};
  DormDocument? _document;
  final List<UploadFile> _pending = [];
  List<DormImage> _images;
  bool _saving = false;
  bool _busyImages = false;
  Object? _error;

  static String _fmt(double? v) => v == null ? '' : v.toString();

  bool get isEdit => existing != null;

  // ---- ค่าที่กรอก ----
  String get name => _name;
  String get address => _address;
  String get price => _price;
  String get totalRooms => _totalRooms;
  String get availableRooms => _availableRooms;
  String get waterRate => _waterRate;
  String get electricityRate => _electricityRate;
  String get description => _description;
  String get contactPhone => _contactPhone;
  String get latitude => _lat;
  String get longitude => _lng;
  String get zone => _zone;
  String? get waterType => _waterType;
  String? get electricityType => _electricityType;
  UtilityMode get waterMode => _waterMode;
  UtilityMode get electricityMode => _electricityMode;
  Set<int> get amenityIds => _amenityIds;
  DormDocument? get document => _document;
  List<Amenity> get catalog => _catalog;
  List<UploadFile> get pending => List.unmodifiable(_pending);
  List<DormImage> get images => List.unmodifiable(_images);
  bool get saving => _saving;
  bool get busyImages => _busyImages;
  Object? get error => _error;

  /// สูงสุดที่เพิ่มรูปได้ในการเลือกครั้งนี้
  int get pickLimit => DormitoryRules.pickLimit(isEdit ? _images.length : _pending.length);

  bool get hasLocation =>
      double.tryParse(_lat.trim()) != null && double.tryParse(_lng.trim()) != null;

  /// ตำแหน่งปัจจุบัน (สำหรับเปิดหน้าปักหมุด)
  LatLng? get currentLocation => hasLocation
      ? LatLng(double.parse(_lat.trim()), double.parse(_lng.trim()))
      : null;

  void _set(VoidCallback change) {
    change();
    notifyListeners();
  }

  void setName(String v) => _set(() => _name = v);
  void setAddress(String v) => _set(() => _address = v);
  void setPrice(String v) => _set(() => _price = v);
  void setTotalRooms(String v) => _set(() => _totalRooms = v);
  void setAvailableRooms(String v) => _set(() => _availableRooms = v);
  void setWaterRate(String v) => _set(() => _waterRate = v);
  void setElectricityRate(String v) => _set(() => _electricityRate = v);
  void setDescription(String v) => _set(() => _description = v);
  void setContactPhone(String v) => _set(() => _contactPhone = v);
  void setZone(String v) => _set(() => _zone = v);
  void setWaterType(String? v) => _set(() => _waterType = v);
  void setElectricityType(String? v) => _set(() => _electricityType = v);
  void setWaterMode(UtilityMode m) => _set(() => _waterMode = m);
  void setElectricityMode(UtilityMode m) => _set(() => _electricityMode = m);

  /// ตั้งพิกัดจากหน้าปักหมุด
  void setLocation(LatLng p) => _set(() {
    _lat = p.latitude.toStringAsFixed(6);
    _lng = p.longitude.toStringAsFixed(6);
  });

  void toggleAmenity(int id) => _set(() {
    final next = {..._amenityIds};
    if (!next.add(id)) next.remove(id);
    _amenityIds = next;
  });

  void setDocument(DormDocument? doc) => _set(() => _document = doc);

  void addPending(List<UploadFile> files) => _set(() => _pending.addAll(files));

  void removePending(int index) => _set(() => _pending.removeAt(index));

  // ---- กติกาการตรวจ (คืนข้อความ error หรือ null) ----
  String? validateName() => DormitoryRules.required(_name);
  String? validatePrice() => DormitoryRules.price(_price);
  String? validateTotalRooms() => DormitoryRules.totalRooms(_totalRooms);
  String? validateAvailableRooms() => DormitoryRules.availableRooms(_availableRooms, _totalRooms);
  String? validateWaterRate() => _waterMode == UtilityMode.setPrice
      ? DormitoryRules.rateRequired(_waterRate)
      : null;
  String? validateWaterBilling() => _waterMode == UtilityMode.setPrice
      ? DormitoryRules.billing(_waterType, _waterRate)
      : null;
  String? validateElectricityRate() => _electricityMode == UtilityMode.setPrice
      ? DormitoryRules.rateRequired(_electricityRate)
      : null;
  String? validateElectricityBilling() => _electricityMode == UtilityMode.setPrice
      ? DormitoryRules.billing(_electricityType, _electricityRate)
      : null;

  /// ฟอร์มผ่านทั้งหมดหรือไม่ (ไม่รวมกติกาเรื่องรูปตอนเพิ่มหอใหม่)
  bool get isValid =>
      validateName() == null &&
      validatePrice() == null &&
      validateTotalRooms() == null &&
      validateAvailableRooms() == null &&
      validateWaterRate() == null &&
      validateWaterBilling() == null &&
      validateElectricityRate() == null &&
      validateElectricityBilling() == null &&
      hasLocation;

  /// โหลดข้อมูลเสริม (amenities, โหมดค่าน้ำไฟ, เอกสาร) คืน true เมื่อสำเร็จ
  Future<bool> loadExtras() async {
    try {
      final x = await _dorms.loadFormExtras(existing);
      _catalog = x.catalog;
      _amenityIds = x.amenityIds.toSet();
      _document = x.document;
      _waterMode = x.waterMode ?? _waterMode;
      _electricityMode = x.electricityMode ?? _electricityMode;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      // ฟีเจอร์เสริมโหลดไม่ได้ ไม่ขวางการกรอกฟอร์มหลัก
      _error = e;
      notifyListeners();
      return false;
    }
  }

  /// บันทึกหอ คืนผลการบันทึก หรือ null ถ้าไม่ผ่านกติกาหรือบันทึกไม่สำเร็จ
  /// ตอนเพิ่มหอใหม่ต้องมีรูปอย่างน้อยหนึ่งรูป
  Future<DormSaveResult?> save() async {
    if (_saving) return null;
    if (!isValid) {
      notifyListeners();
      return null;
    }
    if (!isEdit && _pending.isEmpty) {
      _error = StateError('Add at least 1 photo');
      notifyListeners();
      return null;
    }
    // หอใหม่ต้องแนบเอกสารความเป็นเจ้าของให้ admin ตรวจ
    if (!isEdit && _document == null) {
      _error = StateError('Attach an ownership document');
      notifyListeners();
      return null;
    }
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      final input = _dorms.buildInput(
        name: _name,
        zone: _zone,
        latitude: _lat,
        longitude: _lng,
        price: _price,
        totalRooms: _totalRooms,
        availableRooms: _availableRooms,
        waterMode: _waterMode,
        waterRateText: _waterRate,
        waterType: _waterType,
        electricityMode: _electricityMode,
        electricityRateText: _electricityRate,
        electricityType: _electricityType,
        address: _address,
        description: _description,
        contactPhone: _contactPhone,
        amenityIds: _amenityIds,
        existingAmenityIds: existing?.amenityIds ?? const [],
      );
      final dormId = await _dorms.save(
        id: existing?.id,
        input: input,
        amenityIds: _amenityIds,
        utilities: DormUtilities(water: _waterMode, electricity: _electricityMode),
        document: _document,
      );
      String? photoError;
      if (_pending.isNotEmpty) {
        try {
          await _dorms.uploadImages(dormId, _pending);
        } catch (e) {
          photoError = 'Dorm saved, but photos were not uploaded: $e';
        }
      }
      return DormSaveResult(dormId: dormId, photoError: photoError);
    } catch (e) {
      _error = e;
      return null;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  /// อัปโหลดรูปเพิ่มให้หอที่มีอยู่แล้ว (แก้ไข) คืน true เมื่อสำเร็จ
  Future<bool> uploadImages(List<UploadFile> files) async {
    final id = existing?.id;
    if (id == null || _busyImages) return false;
    if (files.isEmpty || files.length > DormitoryRules.maxImagesPerPick) return false;
    if (_images.length + files.length > DormitoryRules.maxImages) return false;
    _busyImages = true;
    _error = null;
    notifyListeners();
    try {
      await _dorms.uploadImages(id, files);
      await reloadImages();
      return true;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _busyImages = false;
      notifyListeners();
    }
  }

  /// ลบรูปของหอที่มีอยู่แล้ว คืน true เมื่อสำเร็จ
  Future<bool> deleteImage(DormImage img) async {
    final id = existing?.id;
    if (id == null || _busyImages) return false;
    _busyImages = true;
    _error = null;
    notifyListeners();
    try {
      await _dorms.deleteImage(id, img.id);
      await reloadImages();
      return true;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _busyImages = false;
      notifyListeners();
    }
  }

  /// โหลดรายการรูปใหม่จากรายละเอียดหอ
  Future<void> reloadImages() async {
    final id = existing?.id;
    if (id == null) return;
    final fresh = await _dorms.get(id);
    _images = List.of(fresh.images);
    notifyListeners();
  }
}
