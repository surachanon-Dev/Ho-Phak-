/// สิ่งอำนวยความสะดวก (ตาราง `amenities`)
class Amenity {
  const Amenity(this.id, this.name);

  final int id;
  final String name;

  factory Amenity.fromJson(Map<String, dynamic> json) =>
      Amenity((json['id'] as num).toInt(), json['name'] as String);
}

/// รายการตั้งต้นตาม Figma O-3 (ลำดับเดียวกับในเฟรม)
/// ⏳ id เป็นของ local เท่านั้น — ห้ามส่งขึ้น backend จนกว่าจะ seed ตารางตรงกัน
const List<Amenity> localAmenityCatalog = [
  Amenity(1, 'Wi-Fi'),
  Amenity(2, 'CCTV'),
  Amenity(3, 'Key card'),
  Amenity(4, 'Air conditioner'),
  Amenity(5, 'Fan'),
  Amenity(6, 'Parking'),
  Amenity(7, 'Washing machine'),
  Amenity(8, 'Elevator'),
  Amenity(9, 'Pets allowed'),
];
