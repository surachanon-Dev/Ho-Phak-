// ข้อมูลตัวอย่างฝั่งนักศึกษา ในรูปแบบเดียวกับที่ backend ส่งมา (ไม่ใช่ test)
// ใช้ได้ทั้ง unit test (ผ่าน fromJson) และ widget test (ใส่ใน fakeBackend)

/// หอ 1 หอ (GET /api/dormitories, GET /api/dormitories/:id)
Map<String, dynamic> dormJson({
  int id = 1,
  String name = 'Sunrise Dorm',
  String zone = 'หน้ามอ',
  int price = 3000,
  int availableRooms = 2,
  double? rating,
  int? reviewCount,
  String? description,
  String? phone,
  double latitude = 19.8795,
  double longitude = 99.8352,
}) => {
  'id': id,
  'name': name,
  'zone': zone,
  'latitude': latitude,
  'longitude': longitude,
  'price_per_month': price,
  'total_rooms': 10,
  'available_rooms': availableRooms,
  'status': 'published',
  'description': description,
  'contact_phone': phone,
  'images': [],
  'amenities': [],
  'rating_avg': rating,
  'review_count': reviewCount,
};

/// รายการโปรด 1 รายการ (GET /api/favorites)
Map<String, dynamic> favoriteJson({
  int id = 1,
  String name = 'Sunrise Dorm',
  String status = 'published',
}) => {
  'id': id,
  'name': name,
  'zone': 'หน้ามอ',
  'price_per_month': 3200,
  'status': status,
  'saved_at': '2026-11-10T10:00:00.000Z',
};

/// รีวิวของฉัน 1 รายการ (GET /api/reviews/me)
Map<String, dynamic> myReviewJson({
  int id = 1,
  String dorm = 'Sunrise Dorm',
  String status = 'pending',
  String? reason,
}) => {
  'id': id,
  'dormitory_id': 10 + id,
  'dormitory_name': dorm,
  'rating': 4,
  'body': 'Clean and quiet',
  'status': status,
  'moderation_reason': reason,
  'created_at': '2026-11-10T10:00:00Z',
};

/// แชท 1 รายการ (GET /api/conversations)
Map<String, dynamic> conversationJson({
  int id = 1,
  String dorm = 'Sunrise Dorm',
  int unread = 0,
  String? last = 'Is there a room left?',
  String dormStatus = 'published',
}) => {
  'id': id,
  'tenant_id': 9,
  'dormitory_name': dorm,
  'dormitory_status': dormStatus,
  'unread_count': unread,
  'last_message': last,
  'last_sent_at': '2026-11-10T10:00:00Z',
};

/// ข้อความ 1 ข้อความในห้องแชท
Map<String, dynamic> messageJson({
  int id = 1,
  int sender = 9,
  String body = 'Hello',
  String? readAt,
}) => {
  'id': id,
  'sender_id': sender,
  'body': body,
  'sent_at': '2026-11-10T10:00:00Z',
  'read_at': readAt,
};

/// การแจ้งเตือน 1 รายการ (GET /api/notifications)
Map<String, dynamic> notificationJson({
  int id = 1,
  String title = 'Your review was published',
  bool read = false,
}) => {
  'id': id,
  'type': 'review',
  'title': title,
  'body': 'Thanks for your review',
  'created_at': '2026-11-10T10:00:00Z',
  'read_at': read ? '2026-11-11T10:00:00Z' : null,
};
