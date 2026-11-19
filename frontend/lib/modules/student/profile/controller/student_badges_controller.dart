import 'package:flutter/foundation.dart';

import '../../../../services/chat_service.dart';
import '../../../../services/notification_service.dart';

/// จำนวนข้อความและการแจ้งเตือนที่ยังไม่อ่าน (แสดงเป็นตัวเลขบนไอคอน)
/// โหลดไม่สำเร็จจะคงค่าเดิมไว้ ไม่แสดง error เพราะเป็นข้อมูลเสริม
class StudentBadgesController extends ChangeNotifier {
  StudentBadgesController({
    required ChatService chats,
    required NotificationService notifications,
  }) : _chats = chats,
       _notifications = notifications;

  final ChatService _chats;
  final NotificationService _notifications;

  int _messages = 0;
  int _notificationsCount = 0;
  bool _disposed = false;

  /// จำนวนข้อความที่ยังไม่อ่าน (รวมทุกแชท)
  int get messages => _messages;

  /// จำนวนการแจ้งเตือนที่ยังไม่อ่าน
  int get notifications => _notificationsCount;

  Future<void> refresh() async {
    final results = await Future.wait<int?>([
      _chats
          .conversations()
          .then<int?>((list) => list.fold<int>(0, (n, c) => n + c.unreadCount))
          .catchError((_) => null),
      _notifications
          .list()
          .then<int?>((list) => list.where((n) => !n.isRead).length)
          .catchError((_) => null),
    ]);
    if (_disposed) return;
    _messages = results[0] ?? _messages;
    _notificationsCount = results[1] ?? _notificationsCount;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
