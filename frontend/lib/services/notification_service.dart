import '../models/notification.dart';
import 'api_client.dart';

class NotificationService {
  NotificationService(this._api);

  final ApiClient _api;

  /// GET /api/notifications → { notifications: [...] } (50 รายการล่าสุด)
  Future<List<AppNotification>> list() async {
    final data = await _api.get('/api/notifications') as Map<String, dynamic>;
    return (data['notifications'] as List)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// PATCH /api/notifications/:id/read
  Future<void> markRead(int id) =>
      _api.patch('/api/notifications/$id/read', const {});
}
