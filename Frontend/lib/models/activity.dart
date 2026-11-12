import 'json_utils.dart';

/// Table: reviews
class Review {
  final int id;
  final int dormitoryId;
  final String? dormName;
  final int userId;
  final String? userName;
  final int rating;
  final String? body;
  final String status; // always 'published' now (no moderation)
  final String? moderationReason;
  final DateTime? createdAt;

  const Review({
    required this.id,
    required this.dormitoryId,
    this.dormName,
    required this.userId,
    this.userName,
    required this.rating,
    this.body,
    required this.status,
    this.moderationReason,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> j) => Review(
        id: asInt(j['id']),
        dormitoryId: asInt(j['dormitory_id']),
        dormName: j['dormitory_name']?.toString(),
        userId: asInt(j['user_id']),
        userName: j['user_name']?.toString(),
        rating: asInt(j['rating']),
        body: j['body']?.toString(),
        status: asStr(j['status'], 'pending'),
        moderationReason: j['moderation_reason']?.toString(),
        createdAt: asDate(j['created_at']),
      );
}

/// Table: conversations (+ last message, unread count)
class Conversation {
  final int id;
  final int tenantId;
  final String tenantName;
  final int ownerId;
  final String ownerName;
  final int? dormitoryId;
  final String? dormName;
  final String? lastMessage;
  final DateTime? lastAt;
  final int unread;

  const Conversation({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.ownerId,
    required this.ownerName,
    this.dormitoryId,
    this.dormName,
    this.lastMessage,
    this.lastAt,
    this.unread = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        id: asInt(j['id']),
        tenantId: asInt(j['tenant_id']),
        tenantName: asStr(j['tenant_name']),
        ownerId: asInt(j['owner_id']),
        ownerName: asStr(j['owner_name']),
        dormitoryId: asNum(j['dormitory_id'])?.toInt(),
        dormName: j['dormitory_name']?.toString(),
        lastMessage: j['last_message']?.toString(),
        lastAt: asDate(j['last_at']),
        unread: asInt(j['unread']),
      );
}

/// Table: messages
class Message {
  final int id;
  final int conversationId;
  final int senderId;
  final String body;
  final DateTime? sentAt;
  final DateTime? readAt;
  const Message({required this.id, required this.conversationId, required this.senderId, required this.body, this.sentAt, this.readAt});

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: asInt(j['id']),
        conversationId: asInt(j['conversation_id']),
        senderId: asInt(j['sender_id']),
        body: asStr(j['body']),
        sentAt: asDate(j['sent_at']),
        readAt: asDate(j['read_at']),
      );
}

/// Table: notifications
class AppNotification {
  final int id;
  final String type;
  final String title;
  final String? body;
  final String? relatedType;
  final int? relatedId;
  final DateTime? readAt;
  final DateTime? createdAt;
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.relatedType,
    this.relatedId,
    this.readAt,
    this.createdAt,
  });
  bool get isRead => readAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: asInt(j['id']),
        type: asStr(j['type']),
        title: asStr(j['title']),
        body: j['body']?.toString(),
        relatedType: j['related_type']?.toString(),
        relatedId: asNum(j['related_id'])?.toInt(),
        readAt: asDate(j['read_at']),
        createdAt: asDate(j['created_at']),
      );
}

/// Table: admin_logs
class AdminLog {
  final int id;
  final int? adminId;
  final String? adminName;
  final String action;
  final String targetType;
  final int? targetId;
  final Map<String, dynamic>? details;
  final DateTime? createdAt;
  const AdminLog({
    required this.id,
    this.adminId,
    this.adminName,
    required this.action,
    required this.targetType,
    this.targetId,
    this.details,
    this.createdAt,
  });

  factory AdminLog.fromJson(Map<String, dynamic> j) => AdminLog(
        id: asInt(j['id']),
        adminId: asNum(j['admin_id'])?.toInt(),
        adminName: j['admin_name']?.toString(),
        action: asStr(j['action']),
        targetType: asStr(j['target_type']),
        targetId: asNum(j['target_id'])?.toInt(),
        details: j['details'] == null ? null : Map<String, dynamic>.from(j['details'] as Map),
        createdAt: asDate(j['created_at']),
      );
}
