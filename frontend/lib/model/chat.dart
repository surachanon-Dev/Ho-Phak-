int _toInt(dynamic v) => v is num ? v.toInt() : int.parse(v.toString());

/// รายการแชทจาก GET /api/conversations
class Conversation {
  Conversation({
    required this.id,
    required this.tenantId,
    required this.dormitoryName,
    required this.dormitoryStatus,
    required this.unreadCount,
    this.lastMessage,
    this.lastSentAt,
  });

  final int id;
  final int tenantId;
  final String dormitoryName;
  final String dormitoryStatus;
  final int unreadCount;
  final String? lastMessage;
  final String? lastSentAt;

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: _toInt(json['id']),
    tenantId: _toInt(json['tenant_id']),
    dormitoryName: json['dormitory_name'] as String,
    dormitoryStatus: (json['dormitory_status'] as String?) ?? '',
    unreadCount: _toInt(json['unread_count'] ?? 0),
    lastMessage: json['last_message'] as String?,
    lastSentAt: json['last_sent_at']?.toString(),
  );
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.senderId,
    required this.body,
    required this.sentAt,
    this.readAt,
  });

  final int id;
  final int senderId;
  final String body;
  final String sentAt;
  final String? readAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: _toInt(json['id']),
    senderId: _toInt(json['sender_id']),
    body: json['body'] as String,
    sentAt: json['sent_at']?.toString() ?? '',
    readAt: json['read_at']?.toString(),
  );
}

/// ผลจาก GET /api/conversations/:id/messages → { messages, read_only }
class ChatThread {
  ChatThread({required this.messages, required this.readOnly});

  final List<ChatMessage> messages;
  final bool readOnly;
}
