/// กติกาของฟอร์มบัญชี owner (เปลี่ยนรหัสผ่าน / แก้โปรไฟล์) — validator คืนข้อความ error
/// หรือ null ถ้าผ่าน ข้อความและเงื่อนไขย้ายมาจากหน้าจอตรงๆ ไม่เปลี่ยนพฤติกรรม
class OwnerAccountRules {
  const OwnerAccountRules._();

  static const minPasswordLength = 8;

  static String? currentPassword(String? v) =>
      (v ?? '').isEmpty ? 'Enter your current password' : null;

  static String? newPassword(String? v, {required String current}) {
    final t = v ?? '';
    if (t.length < minPasswordLength) return 'Use at least 8 characters';
    if (t == current) return 'New password must be different';
    return null;
  }

  static String? confirmPassword(String? v, {required String next}) =>
      v == next ? null : 'Passwords do not match';

  static String? phone(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Enter your phone number';
    return isThaiMobile(t) ? null : 'Enter a valid phone number';
  }

  /// เบอร์มือถือไทย 10 หลักแบบเดียวกับ backend (`normalizePhone`): ตัดช่องว่างและ -
  /// แปลง +66 เป็น 0 แล้วต้องเป็น 0 ตามด้วยตัวเลข 9 หลัก
  static bool isThaiMobile(String value) {
    var p = value.replaceAll(RegExp(r'[\s-]'), '');
    if (p.startsWith('+66')) p = '0${p.substring(3)}';
    return RegExp(r'^0\d{9}$').hasMatch(p);
  }

  /// ต้องกรอกรหัสผ่านเมื่อเปลี่ยนเบอร์โทร
  static String? passwordForPhoneChange(
    String? v, {
    required bool phoneChanged,
  }) => phoneChanged && (v ?? '').isEmpty
      ? 'Enter your password to change your phone number'
      : null;
}
