import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../services/auth_service.dart';

/// ข้อมูลฟอร์มสมัครสมาชิก
class RegisterInput {
  const RegisterInput({
    this.username = '',
    this.firstName = '',
    this.surname = '',
    required this.phone,
    required this.password,
    required this.confirmPassword,
    this.role,
  });

  /// ชื่อผู้ใช้ (ไม่บังคับ)
  final String username;
  final String firstName;
  final String surname;
  final String phone;
  final String password;
  final String confirmPassword;

  /// 'owner' = สมัครเป็นเจ้าของหอพัก, อย่างอื่น/null = นักศึกษา
  final String? role;

  bool get isOwner => role == 'owner';
}

/// หน้าสมัครสมาชิก: ตรวจฟอร์ม ส่งคำขอ และแปลงข้อผิดพลาดเบอร์ซ้ำเป็นข้อความในฟอร์ม
///
/// backend สร้างบัญชีเป็นนักศึกษาเสมอ ถ้าเลือก "เจ้าของหอพัก" จะ login ชั่วคราว
/// แล้วเรียก POST /api/me/become-owner ต่อ จากนั้น logout ให้ผู้ใช้เข้าสู่ระบบเอง
class RegisterController extends ChangeNotifier {
  RegisterController(this._auth);

  final AuthService _auth;

  static const duplicatePhoneMessage = 'เบอร์โทรนี้ถูกใช้แล้ว';
  static const minPasswordLength = 8;
  static const maxUsernameLength = 50;

  bool _loading = false;
  String? _error;
  Object? _failure;
  bool _done = false;

  bool get loading => _loading;

  /// ข้อความใต้ฟอร์ม (เช่น เบอร์ซ้ำ)
  String? get error => _error;

  /// ข้อผิดพลาดอื่นจาก API ให้หน้าจอแสดงด้วย showApiError
  Object? get failure => _failure;

  /// true เมื่อสมัครสำเร็จแล้ว
  bool get done => _done;

  static String? validateRequired(String? value, String message) =>
      (value == null || value.trim().isEmpty) ? message : null;

  static String? validatePassword(String? value) =>
      (value == null || value.length < minPasswordLength)
      ? 'รหัสผ่านต้องยาวอย่างน้อย $minPasswordLength ตัว'
      : null;

  static String? validateConfirm(String? value, String password) =>
      value != password ? 'รหัสผ่านไม่ตรงกัน' : null;

  /// ชื่อผู้ใช้: ไม่บังคับ แต่ต้องไม่เกิน 50 ตัว
  static String? validateUsername(String? value) =>
      (value ?? '').trim().length > maxUsernameLength
      ? 'ชื่อผู้ใช้ต้องไม่เกิน $maxUsernameLength ตัวอักษร'
      : null;

  /// เบอร์: ต้องกรอก และเป็นเบอร์ 10 หลักขึ้นต้นด้วย 0 (หรือ +66) เว้นวรรค/ขีดได้ ตรงกับที่ backend ตรวจ
  static String? validatePhone(String? value) {
    final v = (value ?? '').replaceAll(RegExp(r'[\s-]'), '');
    if (v.isEmpty) return 'กรุณากรอกเบอร์โทรศัพท์';
    final local = v.startsWith('+66') ? '0${v.substring(3)}' : v;
    return RegExp(r'^0\d{9}$').hasMatch(local)
        ? null
        : 'เบอร์โทรต้องเป็นตัวเลข 10 หลัก ขึ้นต้นด้วย 0';
  }

  /// เบอร์ซ้ำ: backend ตอบ 409 พร้อมข้อความที่มีคำว่า "เบอร์" หรือ "ถูกใช้"
  static bool isDuplicatePhone(Object error) {
    if (error is! ApiException) return false;
    if (error.statusCode != 409) return false;
    return error.message.contains('เบอร์') || error.message.contains('ถูกใช้');
  }

  /// สมัครสมาชิก คืน true เมื่อสำเร็จ
  Future<bool> submit(RegisterInput input) async {
    if (_loading) return false;
    _error = null;
    _failure = null;
    _loading = true;
    notifyListeners();
    final phone = input.phone.trim();
    final username = input.username.trim();
    try {
      // ส่ง username เฉพาะตอนกรอก (รูปแบบการเรียกเดิมไม่เปลี่ยน)
      if (username.isEmpty) {
        await _auth.register(
          phone,
          input.password,
          input.confirmPassword,
          firstName: input.firstName.trim(),
          surname: input.surname.trim(),
        );
      } else {
        await _auth.register(
          phone,
          input.password,
          input.confirmPassword,
          username: username,
          firstName: input.firstName.trim(),
          surname: input.surname.trim(),
        );
      }
      if (input.isOwner) await _upgradeToOwner(phone, input.password);
      _done = true;
      return true;
    } catch (e) {
      if (isDuplicatePhone(e)) {
        _error = duplicatePhoneMessage;
      } else {
        _failure = e;
      }
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// เปลี่ยนบัญชีที่เพิ่งสมัครเป็นเจ้าของหอ แล้วออกจากระบบเสมอ (ผู้ใช้จะเข้าสู่ระบบเองหลังจากนี้)
  Future<void> _upgradeToOwner(String phone, String password) async {
    try {
      final user = await _auth.login(phone, password);
      if (user == null) {
        throw ApiException(401, 'สมัครสำเร็จ แต่เปลี่ยนเป็นเจ้าของหอไม่สำเร็จ กรุณาเข้าสู่ระบบแล้วลองใหม่');
      }
      await _auth.becomeOwner();
    } finally {
      await _auth.logout();
    }
  }
}
