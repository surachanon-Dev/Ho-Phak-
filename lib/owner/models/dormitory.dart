/// โซนของหอ
const dormitoryZones = ['หน้ามอ', 'หลังมอ', 'คชพลแลนด์'];

class Dormitory {
  const Dormitory({
    required this.id,
    required this.name,
    required this.zone,
    required this.latitude,
    required this.longitude,
    required this.pricePerMonth,
  });

  final int id;
  final String name;
  final String zone;
  final double latitude;
  final double longitude;
  final int pricePerMonth;
}
