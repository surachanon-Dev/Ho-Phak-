import 'json_utils.dart';

/// Table: amenities
class Amenity {
  final int id;
  final String name;
  const Amenity(this.id, this.name);
  factory Amenity.fromJson(Map<String, dynamic> j) => Amenity(asInt(j['id']), asStr(j['name']));
}

/// Table: dormitory_images
class DormImage {
  final int id;
  final String filePath;
  final int sortOrder;
  const DormImage(this.id, this.filePath, this.sortOrder);
  factory DormImage.fromJson(Map<String, dynamic> j) =>
      DormImage(asInt(j['id']), asStr(j['file_path']), asInt(j['sort_order']));
}

/// Table: dormitories (+ owner info, images, amenities, rating)
class Dormitory {
  final int id;
  final int ownerId;
  final String? ownerName;
  final String? ownerPhone;
  final String name;
  final String zone;
  final double latitude;
  final double longitude;
  final int pricePerMonth;
  final num? waterRate;
  final String? waterBillingType;
  final num? electricityRate;
  final String? electricityBillingType;
  final String? description;
  final String? address;
  final String? contactPhone;
  final String? ownershipDocumentUrl; // NEW column: document proving ownership (attached when adding the dorm)
  final String status; // pending | published | rejected | hidden | suspended
  final String? statusReason;
  final String? rejectionReason;
  final DateTime? statusChangedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<DormImage> images;
  final List<Amenity> amenities;
  final num? avgRating;
  final int reviewCount;
  final int? distanceMeters; // from campus

  const Dormitory({
    required this.id,
    required this.ownerId,
    this.ownerName,
    this.ownerPhone,
    required this.name,
    required this.zone,
    required this.latitude,
    required this.longitude,
    required this.pricePerMonth,
    this.waterRate,
    this.waterBillingType,
    this.electricityRate,
    this.electricityBillingType,
    this.description,
    this.address,
    this.contactPhone,
    this.ownershipDocumentUrl,
    required this.status,
    this.statusReason,
    this.rejectionReason,
    this.statusChangedAt,
    this.createdAt,
    this.updatedAt,
    this.images = const [],
    this.amenities = const [],
    this.avgRating,
    this.reviewCount = 0,
    this.distanceMeters,
  });

  String? get coverImage => images.isEmpty ? null : images.first.filePath;
  bool get isVisibleToStudents => status == 'published';

  factory Dormitory.fromJson(Map<String, dynamic> j) => Dormitory(
        id: asInt(j['id']),
        ownerId: asInt(j['owner_id']),
        ownerName: j['owner_name']?.toString(),
        ownerPhone: j['owner_phone']?.toString(),
        name: asStr(j['name']),
        zone: asStr(j['zone']),
        latitude: asDouble(j['latitude']),
        longitude: asDouble(j['longitude']),
        pricePerMonth: asInt(j['price_per_month']),
        waterRate: asNum(j['water_rate']),
        waterBillingType: j['water_billing_type']?.toString(),
        electricityRate: asNum(j['electricity_rate']),
        electricityBillingType: j['electricity_billing_type']?.toString(),
        description: j['description']?.toString(),
        address: j['address']?.toString(),
        contactPhone: j['contact_phone']?.toString(),
        ownershipDocumentUrl: j['ownership_document_url']?.toString(),
        status: asStr(j['status'], 'pending'),
        statusReason: j['status_reason']?.toString(),
        rejectionReason: j['rejection_reason']?.toString(),
        statusChangedAt: asDate(j['status_changed_at']),
        createdAt: asDate(j['created_at']),
        updatedAt: asDate(j['updated_at']),
        images: ((j['images'] as List?) ?? []).map((e) => DormImage.fromJson(e as Map<String, dynamic>)).toList(),
        amenities: ((j['amenities'] as List?) ?? []).map((e) => Amenity.fromJson(e as Map<String, dynamic>)).toList(),
        avgRating: asNum(j['avg_rating']),
        reviewCount: asInt(j['review_count']),
        distanceMeters: asNum(j['distance_meters'])?.toInt(),
      );
}
