// ข้อมูลตัวอย่างฝั่งเจ้าของหอ ในรูปแบบเดียวกับที่ backend ส่งมา (ไม่ใช่ test)
// ใช้คู่กับ fakeBackend: ownerRoutes() สร้างชุด route พื้นฐานของหน้า owner ให้
import 'package:hopak_frontend/model/user.dart';

/// เจ้าของหอที่ login อยู่ ([verified] = false → ถูกส่งไปหน้ายืนยันตัวตน)
CurrentUser ownerUser({bool verified = true}) => CurrentUser(
  id: 7,
  role: 'owner',
  status: 'active',
  isVerified: verified,
  username: 'somchai',
);

/// หอ 1 หอของเจ้าของ (GET /api/owner/dormitories, GET /api/owner/dormitories/:id)
Map<String, dynamic> ownerDormJson({
  int id = 1,
  String name = 'Baan Suan',
  String status = 'published',
  int price = 3200,
  int total = 10,
  int available = 4,
  String? rejectionReason,
}) => {
  'id': id,
  'name': name,
  'zone': 'หน้ามอ',
  'latitude': '19.9500',
  'longitude': '99.8900',
  'price_per_month': price,
  'total_rooms': total,
  'available_rooms': available,
  'status': status,
  'description': 'Quiet dorm near campus',
  'address': '1 Moo 1',
  'contact_phone': '0812345678',
  'rejection_reason': rejectionReason,
  'amenity_ids': <int>[],
  'images': <Map<String, dynamic>>[],
};

/// รีวิว 1 รายการของหอ (GET /api/owner/dormitories/:id/reviews)
Map<String, dynamic> ownerReviewJson({
  int id = 1,
  int rating = 5,
  String body = 'Great place',
}) => {
  'id': id,
  'rating': rating,
  'body': body,
  'created_at': '2026-11-01T10:00:00.000Z',
};

/// โปรไฟล์เจ้าของ (GET /api/me/profile)
Map<String, dynamic> ownerProfileJson({
  String firstName = 'Somchai',
  String surname = 'Jaidee',
  String phone = '0812345678',
}) => {
  'first_name': firstName,
  'surname': surname,
  'phone': phone,
  'pending_phone': null,
};

/// route พื้นฐานของหน้า owner สำหรับ fakeBackend
/// [dorms] = หอของเจ้าของ, [reviews] = รีวิวของแต่ละหอ (key = dorm id),
/// [verification] = ผลของ GET /api/owner/verification (null = ยังไม่เคยส่ง)
/// [extra] = route เพิ่มเติม/ทับของเดิม เช่น 'PUT /api/me/password'
Map<String, Object> ownerRoutes({
  List<Map<String, dynamic>> dorms = const [],
  Map<int, List<Map<String, dynamic>>> reviews = const {},
  Map<String, dynamic>? verification,
  Map<String, dynamic>? notificationPrefs,
  Map<String, Object> extra = const {},
}) => {
  'GET /api/owner/dormitories': {'dormitories': dorms},
  for (final d in dorms) ...{
    'GET /api/owner/dormitories/${d['id']}': {'dormitory': d},
    'GET /api/owner/dormitories/${d['id']}/reviews': {
      'reviews': reviews[d['id']] ?? const [],
    },
    'GET /api/owner/dormitories/${d['id']}/utilities': {
      'water': 'not_specified',
      'electricity': 'not_specified',
    },
  },
  'GET /api/amenities': {
    'amenities': [
      {'id': 1, 'name': 'Wi-Fi'},
      {'id': 2, 'name': 'Parking'},
    ],
  },
  'GET /api/owner/review-reports': {'reports': <Object>[]},
  'GET /api/owner/verification': {'verification': verification},
  'GET /api/me/profile': {'profile': ownerProfileJson()},
  'GET /api/me/notification-settings':
      notificationPrefs ??
      {'messages': true, 'approvals': true, 'reviews': false},
  'GET /api/conversations': {'conversations': <Object>[]},
  ...extra,
};
