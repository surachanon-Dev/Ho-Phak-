int _toInt(dynamic v) => v is num ? v.toInt() : int.parse(v.toString());

/// การแจ้งเตือนจาก GET /api/notifications
class AppNotification {
  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
    this.body,
    this.readAt,
  });

  final int id;
  final String type;
  final String title;
  final String? body;
  final String createdAt;
  final String? readAt;

  bool get isRead => readAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: _toInt(json['id']),
        type: (json['type'] as String?) ?? '',
        title: (json['title'] as String?) ?? '',
        body: json['body'] as String?,
        createdAt: json['created_at']?.toString() ?? '',
        readAt: json['read_at']?.toString(),
      );
}
