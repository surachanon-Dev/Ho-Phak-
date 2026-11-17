import 'package:flutter/foundation.dart';

import '../../../shared/models/user.dart';
import '../../auth/services/auth_service.dart';

/// โปรไฟล์แอดมิน: โหลดบัญชีที่ login อยู่ และออกจากระบบ
class AdminProfileController extends ChangeNotifier {
  AdminProfileController(this._auth);

  final AuthService _auth;

  CurrentUser? _user;
  bool _loading = true;
  Object? _error;

  CurrentUser? get user => _user;
  bool get loading => _loading;
  Object? get error => _error;

  Future<bool> load() async {
    _loading = true;
    notifyListeners();
    try {
      _user = await _auth.currentUser();
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
