import 'package:flutter/foundation.dart';

import '../../../shared/models/notification.dart';
import '../services/notification_service.dart';

/// การแจ้งเตือน: โหลดรายการ ทำเครื่องหมายว่าอ่านแล้ว และนับจำนวนที่ยังไม่อ่าน
class NotificationsController extends ChangeNotifier {
  NotificationsController(this._notifications);

  final NotificationService _notifications;

  List<AppNotification> _items = const [];
  bool _loading = true;
  Object? _error;

  List<AppNotification> get items => _items;
  bool get loading => _loading;

  /// error ล่าสุด (โหลดหรืออ่านไม่สำเร็จ) ให้หน้าจอแสดงด้วย showApiError
  Object? get error => _error;

  /// แสดงสปินเนอร์เต็มหน้าเฉพาะตอนที่ยังไม่มีข้อมูล
  bool get showFullLoader => _loading && _items.isEmpty;

  /// จำนวนที่ยังไม่ได้อ่าน
  int get unreadCount => _items.where((n) => !n.isRead).length;

  Future<bool> load() async {
    _loading = true;
    notifyListeners();
    try {
      _items = await _notifications.list();
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

  /// กดรายการ: ถ้ายังไม่อ่านให้ทำเครื่องหมายอ่านแล้ว แล้วโหลดรายการใหม่
  /// คืน true เมื่อทั้งหมดสำเร็จ
  Future<bool> open(AppNotification n) async {
    Object? readError;
    if (!n.isRead) {
      try {
        await _notifications.markRead(n.id);
      } catch (e) {
        readError = e;
      }
    }
    // โหลดใหม่เสมอ ให้สถานะอ่านแล้วตรงกับ backend
    final loaded = await load();
    if (readError != null) {
      _error = readError;
      notifyListeners();
      return false;
    }
    return loaded;
  }
}
