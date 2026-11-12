import '../mock/mock_db.dart';
import '../models/activity.dart';

/// notifications (MOCK)
class NotificationService {
  final _db = MockDb.instance;

  Future<List<AppNotification>> list() async {
    await MockDb.delay(150);
    final me = _db.currentUser['id'];
    final rows = _db.notifications.where((n) => n['user_id'] == me).toList()
      ..sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
    return rows.map(AppNotification.fromJson).toList();
  }

  Future<int> unreadCount() async {
    final me = _db.currentUserId;
    return _db.notifications.where((n) => n['user_id'] == me && n['read_at'] == null).length;
  }

  Future<void> markRead(int id) async {
    final me = _db.currentUser['id'];
    for (final n in _db.notifications.where((n) => n['id'] == id && n['user_id'] == me)) {
      n['read_at'] ??= MockDb.now();
    }
  }

  Future<void> markAllRead() async {
    final me = _db.currentUser['id'];
    for (final n in _db.notifications.where((n) => n['user_id'] == me)) {
      n['read_at'] ??= MockDb.now();
    }
  }
}
