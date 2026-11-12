import 'package:flutter/foundation.dart';

import '../services/chat_service.dart';
import '../services/notification_service.dart';

/// Unread counters for the bell (notifications) and chat icons in every app bar
class BadgeController extends ChangeNotifier {
  BadgeController(this._notes, this._chat);
  final NotificationService _notes;
  final ChatService _chat;

  int notifications = 0;
  int messages = 0;

  Future<void> refresh() async {
    try {
      notifications = await _notes.unreadCount();
      messages = await _chat.unreadCount();
    } catch (_) {
      notifications = 0;
      messages = 0;
    }
    notifyListeners();
  }
}
