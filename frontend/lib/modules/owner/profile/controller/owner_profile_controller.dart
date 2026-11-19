import 'package:flutter/foundation.dart';

import '../../../../services/auth_service.dart';
import '../../../../services/owner_account_service.dart';
import '../../../../model/owner_profile.dart';

/// หน้า "โปรไฟล์" ของ owner: โหลดโปรไฟล์ (มี fallback เป็นชื่อผู้ใช้) และออกจากระบบ
class OwnerProfileController extends ChangeNotifier {
  OwnerProfileController({
    required OwnerAccountService account,
    required AuthService auth,
    required this.fallbackName,
  }) : _account = account,
       _auth = auth;

  final OwnerAccountService _account;
  final AuthService _auth;

  /// ชื่อที่ใช้แทนเมื่อโหลดโปรไฟล์ไม่ได้ (มาจาก username)
  final String? fallbackName;

  OwnerProfile _profile = const OwnerProfile();
  bool _loading = false;
  Object? _error;

  OwnerProfile get profile => _profile;
  bool get loading => _loading;

  /// error ของการโหลดโปรไฟล์ (การโหลดล้มเหลวไม่ได้ทำให้หน้าพัง จึงเก็บไว้เฉย ๆ)
  Object? get error => _error;

  Future<bool> load() async {
    _loading = true;
    notifyListeners();
    try {
      _profile = await _account.profile(fallbackName: fallbackName);
      _error = null;
      return true;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// ออกจากระบบ (ลบ token ในเครื่องเสมอ)
  Future<void> logout() => _auth.logout();
}
