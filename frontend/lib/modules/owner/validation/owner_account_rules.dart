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
    return RegExp(r'^[0-9+\- ]{9,15}$').hasMatch(t)
        ? null
        : 'Enter a valid phone number';
  }

  /// ต้องกรอกรหัสผ่านเมื่อเปลี่ยนเบอร์โทร
  static String? passwordForPhoneChange(
    String? v, {
    required bool phoneChanged,
  }) => phoneChanged && (v ?? '').isEmpty
      ? 'Enter your password to change your phone number'
      : null;
}
