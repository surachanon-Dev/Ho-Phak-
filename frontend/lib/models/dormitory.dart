// โซนที่ backend รับได้ ต้องตรงกับ enum ใน DB
const List<String> dormitoryZones = ['หน้ามอ', 'หลังมอ', 'คชพลแลนด์'];

class Dormitory {
  final int id;
  final String name;
  final String zone;
  final double latitude;
  final double longitude;
  final int pricePerMonth;

  Dormitory({
    required this.id,
    required this.name,
    required this.zone,
    required this.latitude,
    required this.longitude,
    required this.pricePerMonth,
  });

  factory Dormitory.fromJson(Map<String, dynamic> json) {
    return Dormitory(
      id: json['id'] as int,
      name: json['name'] as String,
      zone: json['zone'] as String,
      // mysql2 ส่ง DECIMAL มาเป็น string จึงต้องแปลงเป็น double ก่อน
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      pricePerMonth: json['price_per_month'] as int,
    );
  }
}
