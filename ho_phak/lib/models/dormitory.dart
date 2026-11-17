class Dormitory {
  final String id;
  final String name;
  final int price;
  final String waterRate;
  final String electricityRate;
  final String location;
  final double distanceKm;
  final String ownerName;
  final String ownerPhone;
  final double rating;
  final String imageUrl;
  final List<String> amenities;
  final double pinTop;
  final double pinLeft;

  const Dormitory({
    required this.id,
    required this.name,
    required this.price,
    required this.waterRate,
    required this.electricityRate,
    required this.location,
    required this.distanceKm,
    required this.ownerName,
    required this.ownerPhone,
    required this.rating,
    required this.imageUrl,
    required this.amenities,
    this.pinTop = 35.0,
    this.pinLeft = 85.0,
  });

  String get formattedPrice => '฿${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}/mo';
}