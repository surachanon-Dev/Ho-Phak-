import 'package:flutter/foundation.dart';

import '../services/owner_account_service.dart';
import '../models/notification_prefs.dart';

/// หน้าตั้งค่าแจ้งเตือน: โหลดค่า สลับสวิตช์ และย้อนค่ากลับถ้าบันทึกไม่สำเร็จ
class NotificationSettingsController extends ChangeNotifier {
  NotificationSettingsController(this._account);

  final OwnerAccountService _account;

  NotificationPrefs? _prefs;
  Object? _error;

  NotificationPrefs? get prefs => _prefs;
  Object? get error => _error;

  Future<bool> load() async {
    try {
      _prefs = await _account.notificationPrefs();
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e;
      notifyListeners();
      return false;
    }
  }

  /// ตั้งค่าใหม่ทันที (แสดงผลทันที) ถ้าบันทึกไม่สำเร็จจะย้อนกลับเป็นค่าเดิม
  Future<bool> update(NotificationPrefs next) async {
    final before = _prefs;
    _prefs = next;
    _error = null;
    notifyListeners();
    try {
      await _account.saveNotificationPrefs(next);
      return true;
    } catch (e) {
      _prefs = before;
      _error = e;
      notifyListeners();
      return false;
    }
  }
}
