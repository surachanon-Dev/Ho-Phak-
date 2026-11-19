import '../../../../model/amenity.dart';
import '../../../../model/dorm_utilities.dart';
import '../../../../model/dorm_document.dart';

/// ข้อมูลเสริมของฟอร์มหอ (ส่วนที่ backend ยังไม่มี) — ดู DormitoryService.loadFormExtras
class DormFormExtras {
  const DormFormExtras({
    this.catalog = const [],
    this.amenityIds = const [],
    this.document,
    this.waterMode,
    this.electricityMode,
  });

  final List<Amenity> catalog;
  final List<int> amenityIds;
  final DormDocument? document;

  /// null = ไม่มีค่าที่บันทึกไว้ (เพิ่มหอใหม่) ให้คงโหมดเดิมในฟอร์ม
  final UtilityMode? waterMode;
  final UtilityMode? electricityMode;
}
