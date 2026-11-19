import '../../../../model/amenity.dart';
import '../../../../model/dorm_utilities.dart';

/// ข้อมูลเสริมของหน้า detail: amenities ที่หอนี้มี + ค่าน้ำไฟ
class DormDetailExtras {
  const DormDetailExtras({this.amenities = const [], this.utilities});
  final List<Amenity> amenities;
  final DormUtilities? utilities;
}
