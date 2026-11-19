class OwnerProfile {
  const OwnerProfile({
    this.firstName = '',
    this.surname = '',
    this.phone = '',
    this.pendingPhone,
    this.photoBase64,
  });

  final String firstName;
  final String surname;

  /// เบอร์ที่ใช้ล็อกอินอยู่
  final String phone;

  /// เบอร์ใหม่ที่รอแอดมินอนุมัติ (O-8a)
  final String? pendingPhone;

  /// รูปโปรไฟล์ (base64) — ฝั่ง API จริงจะเปลี่ยนเป็น URL ตอนเชื่อม
  final String? photoBase64;

  String get fullName => '$firstName $surname'.trim();

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'surname': surname,
    'phone': phone,
    'pending_phone': pendingPhone,
    'photo': photoBase64,
  };

  factory OwnerProfile.fromJson(Map<String, dynamic> json) => OwnerProfile(
    firstName: (json['first_name'] as String?) ?? '',
    surname: (json['surname'] as String?) ?? '',
    phone: (json['phone'] as String?) ?? '',
    pendingPhone: json['pending_phone'] as String?,
    photoBase64: json['photo'] as String?,
  );
}
