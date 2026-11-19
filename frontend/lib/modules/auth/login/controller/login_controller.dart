import 'package:flutter/foundation.dart';

import '../../../../model/user.dart';
import '../../../../services/auth_service.dart';

/// หน้า Sign In: ตรวจค่าในฟอร์ม เรียก login และเก็บสถานะ
class LoginController extends ChangeNotifier {
  LoginController(this._auth);

  final AuthService _auth;

  bool _loading = false;
  String? _error;
  Object? _failure;
  CurrentUser? _user;

  /// true ระหว่างเรียก API
  bool get loading => _loading;

  /// ข้อความแสดงใต้ฟอร์ม เมื่อเบอร์หรือรหัสผ่านไม่ถูกต้อง
  String? get error => _error;

  /// ข้อผิดพลาดอื่นจาก API (เช่น บัญชีถูกระงับ, เชื่อมต่อไม่ได้) ให้หน้าจอแสดงด้วย showApiError
  Object? get failure => _failure;

  /// ผู้ใช้ที่ login สำเร็จล่าสุด
  CurrentUser? get user => _user;

  static const invalidCredentialsMessage =
      'Wrong phone number or password. Please try again.';

  /// ตรวจเบอร์: ต้องไม่ว่าง
  static String? validatePhone(String? value) =>
      (value == null || value.trim().isEmpty)
      ? 'Please enter your phone number'
      : null;

  /// ตรวจรหัสผ่าน: ต้องไม่ว่าง
  static String? validatePassword(String? value) =>
      (value == null || value.isEmpty) ? 'Please enter your password' : null;

  /// login คืน true เมื่อสำเร็จ (ดู [user]) ค่าผิดพลาดดู [error] หรือ [failure]
  Future<bool> submit({required String phone, required String password}) async {
    if (_loading) return false;
    if (validatePhone(phone) != null || validatePassword(password) != null) {
      _error = null;
      _failure = null;
      notifyListeners();
      return false;
    }
    _loading = true;
    _error = null;
    _failure = null;
    notifyListeners();
    try {
      final user = await _auth.login(phone.trim(), password);
      if (user == null) {
        _error = invalidCredentialsMessage;
        return false;
      }
      _user = user;
      return true;
    } catch (e) {
      _failure = e;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
