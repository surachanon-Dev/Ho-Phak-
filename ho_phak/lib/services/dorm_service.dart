import '../models/dormitory.dart';

class DormService {
  static final List<Dormitory> _dorms = [
    const Dormitory(
      id: 'dorm_1',
      name: 'Hopak Sukjai 1',
      price: 3500,
      waterRate: '18 THB/unit',
      electricityRate: '7 THB/unit',
      location: 'Front Gate · 0.3 km from MFU',
      distanceKm: 0.3,
      ownerName: 'Bank',
      ownerPhone: '081-234-5678',
      rating: 4.5,
      imageUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800',
      amenities: ['Air Conditioner', 'Free Wi-Fi', 'Parking', 'CCTV'],
      pinTop: 35.0,
      pinLeft: 85.0,
    ),
    const Dormitory(
      id: 'dorm_2',
      name: 'Hopak Sukjai 2',
      price: 4200,
      waterRate: '18 THB/unit',
      electricityRate: '7 THB/unit',
      location: 'Front Gate · 0.5 km from MFU',
      distanceKm: 0.5,
      ownerName: 'Somchai',
      ownerPhone: '089-876-5432',
      rating: 4.7,
      imageUrl: 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800',
      amenities: ['Air Conditioner', 'Free Wi-Fi', 'Parking', 'CCTV', 'Washing Machine'],
      pinTop: 22.0,
      pinLeft: 65.0,
    ),
    const Dormitory(
      id: 'dorm_3',
      name: 'Hopak Sukjai 3',
      price: 3800,
      waterRate: '15 THB/unit',
      electricityRate: '7 THB/unit',
      location: 'Side Gate · 0.8 km from MFU',
      distanceKm: 0.8,
      ownerName: 'Malee',
      ownerPhone: '086-555-1234',
      rating: 4.6,
      imageUrl: 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800',
      amenities: ['Air Conditioner', 'Free Wi-Fi', 'CCTV'],
      pinTop: 28.0,
      pinLeft: 140.0,
    ),
    const Dormitory(
      id: 'dorm_4',
      name: 'Hopak Sukjai 4',
      price: 4500,
      waterRate: '18 THB/unit',
      electricityRate: '8 THB/unit',
      location: 'Market Zone · 1.2 km from MFU',
      distanceKm: 1.2,
      ownerName: 'Nattapong',
      ownerPhone: '082-333-9999',
      rating: 4.8,
      imageUrl: 'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?w=800',
      amenities: ['Air Conditioner', 'Free Wi-Fi', 'Parking', 'CCTV', 'Keycard'],
      pinTop: 55.0,
      pinLeft: 160.0,
    ),
  ];

  List<Dormitory> getAllDorms() => _dorms;

  Dormitory getByName(String name) {
    return _dorms.firstWhere(
      (d) => d.name == name,
      orElse: () => _dorms.first,
    );
  }
}