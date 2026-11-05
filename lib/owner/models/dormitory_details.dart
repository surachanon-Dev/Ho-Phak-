import '../views/utils/formatters.dart';

enum DormitoryStatus { approved, pending, rejected }

enum WaterBilling { perUnit, flat }

const dormitoryAmenities = [
  'Wi-Fi',
  'แอร์',
  'เครื่องทำน้ำอุ่น',
  'ที่จอดรถ',
  'กล้องวงจรปิด',
  'คีย์การ์ด',
  'เครื่องซักผ้า',
  'ตู้เย็น',
];

/// รายละเอียดเพิ่มเติมของหอ นอกเหนือจากชื่อ โซน พิกัด ราคา
class DormitoryDetails {
  const DormitoryDetails({
    this.status = DormitoryStatus.pending,
    this.rejectReason,
    this.published = false,
    this.availableRooms,
    this.waterRate,
    this.waterBilling = WaterBilling.perUnit,
    this.electricRate,
    this.deposit,
    this.address = '',
    this.description = '',
    this.amenities = const {},
  });

  final DormitoryStatus status;
  final String? rejectReason;
  final bool published;
  final int? availableRooms;
  final double? waterRate;
  final WaterBilling waterBilling;
  final double? electricRate;
  final int? deposit;
  final String address;
  final String description;
  final Set<String> amenities;

  DormitoryDetails withPublished(bool value) => DormitoryDetails(
        status: status,
        rejectReason: rejectReason,
        published: value,
        availableRooms: availableRooms,
        waterRate: waterRate,
        waterBilling: waterBilling,
        electricRate: electricRate,
        deposit: deposit,
        address: address,
        description: description,
        amenities: amenities,
      );

  bool get approved => status == DormitoryStatus.approved;

  String get waterText => waterRate == null
      ? '—'
      : waterBilling == WaterBilling.flat
          ? 'เหมา ${withCommas(waterRate!)} บ.'
          : '${withCommas(waterRate!)} บ./หน่วย';

  String get electricText => electricRate == null ? '—' : '${withCommas(electricRate!)} บ./หน่วย';

  String get depositText => deposit == null ? '—' : '${withCommas(deposit!)} บ.';
}
