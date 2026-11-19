import 'package:flutter/foundation.dart';

import '../../validation/owner_account_rules.dart';
import '../../../../services/owner_account_service.dart';

/// หน้าเปลี่ยนรหัสผ่าน: ตรวจกติกาด้วย [OwnerAccountRules] และส่งคำขอ
class ChangePasswordController extends ChangeNotifier {
  ChangePasswordController(this._account);

  final OwnerAccountService _account;

  String _current = '';
  String _next = '';
  String _confirm = '';
  bool _saving = false;
  Object? _error;

  bool get saving => _saving;
  Object? get error => _error;

  void setCurrent(String v) => _set(() => _current = v);
  void setNext(String v) => _set(() => _next = v);
  void setConfirm(String v) => _set(() => _confirm = v);

  void _set(VoidCallback change) {
    change();
    notifyListeners();
  }

  String? validateCurrent() => OwnerAccountRules.currentPassword(_current);
  String? validateNext() =>
      OwnerAccountRules.newPassword(_next, current: _current);
  String? validateConfirm() =>
      OwnerAccountRules.confirmPassword(_confirm, next: _next);

  bool get isValid =>
      validateCurrent() == null &&
      validateNext() == null &&
      validateConfirm() == null;

  /// คืน true เมื่อเปลี่ยนรหัสผ่านสำเร็จ
  Future<bool> submit() async {
    if (_saving || !isValid) {
      notifyListeners();
      return false;
    }
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      await _account.changePassword(current: _current, next: _next);
      return true;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}
