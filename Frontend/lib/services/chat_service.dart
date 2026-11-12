import '../core/api_client.dart';
import '../mock/mock_db.dart';
import '../models/activity.dart';

/// conversations + messages (MOCK). A conversation = 1 student (tenant) + 1 owner (+ the dorm it is about).
/// Each side can delete it for themselves (deleted_by_tenant_at / deleted_by_owner_at).
class ChatService {
  final _db = MockDb.instance;

  bool _isTenant(Map<String, dynamic> c, int me) => c['tenant_id'] == me;

  Map<String, dynamic> _mine(int id) {
    final me = _db.currentUser['id'] as int;
    final c = _db.conversations.where((c) => c['id'] == id).firstOrNull;
    if (c == null || (c['tenant_id'] != me && c['owner_id'] != me)) throw ApiException(404, 'ไม่พบบทสนทนา');
    return c;
  }

  Map<String, dynamic> _json(Map<String, dynamic> c, int me) {
    final msgs = _db.messages.where((m) => m['conversation_id'] == c['id']).toList()
      ..sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
    final last = msgs.isEmpty ? null : msgs.last;
    return {
      ...c,
      'tenant_name': _db.nameOf(c['tenant_id'] as int),
      'owner_name': _db.nameOf(c['owner_id'] as int),
      'dormitory_name': _db.dormById(c['dormitory_id'] as int?)?['name'],
      'last_message': last?['body'],
      'last_at': last?['sent_at'] ?? c['created_at'],
      'unread': msgs.where((m) => m['sender_id'] != me && m['read_at'] == null).length,
    };
  }

  Future<List<Conversation>> conversations() async {
    await MockDb.delay(200);
    final me = _db.currentUser['id'] as int;
    final list = _db.conversations
        .where((c) => (c['tenant_id'] == me && c['deleted_by_tenant_at'] == null) || (c['owner_id'] == me && c['deleted_by_owner_at'] == null))
        .map((c) => _json(c, me))
        .toList()
      ..sort((a, b) => (b['last_at'] as String).compareTo(a['last_at'] as String));
    return list.map(Conversation.fromJson).toList();
  }

  Future<int> unreadCount() async {
    final list = await conversations();
    return list.fold<int>(0, (n, c) => n + c.unread);
  }

  /// Student taps "แชทกับเจ้าของ" on a dorm. UNIQUE(dormitory_id, tenant_id, owner_id) → reuse the existing one.
  Future<Conversation> startWithOwner(int dormId) async {
    final me = _db.requireRole('student')['id'] as int;
    final d = _db.dormById(dormId);
    if (d == null) throw ApiException(404, 'ไม่พบหอพัก');
    var c = _db.conversations.where((c) => c['dormitory_id'] == dormId && c['tenant_id'] == me && c['owner_id'] == d['owner_id']).firstOrNull;
    if (c == null) {
      c = {
        'id': _db.nextId('conversations'),
        'tenant_id': me,
        'owner_id': d['owner_id'],
        'dormitory_id': dormId,
        'created_at': MockDb.now(),
        'deleted_by_tenant_at': null,
        'deleted_by_owner_at': null,
      };
      _db.conversations.add(c);
    }
    c['deleted_by_tenant_at'] = null;
    return Conversation.fromJson(_json(c, me));
  }

  Future<Conversation> get(int id) async => Conversation.fromJson(_json(_mine(id), _db.currentUser['id'] as int));

  /// Opening a chat marks the other side's messages as read (messages.read_at)
  Future<List<Message>> messages(int conversationId) async {
    final c = _mine(conversationId);
    final me = _db.currentUser['id'] as int;
    final list = _db.messages.where((m) => m['conversation_id'] == c['id']).toList()
      ..sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
    for (final m in list) {
      if (m['sender_id'] != me && m['read_at'] == null) m['read_at'] = MockDb.now();
    }
    return list.map(Message.fromJson).toList();
  }

  Future<void> send(int conversationId, String body) async {
    final text = body.trim();
    if (text.isEmpty) return;
    final c = _mine(conversationId);
    final me = _db.currentUser['id'] as int;
    await MockDb.delay(150);
    _db.messages.add({
      'id': _db.nextId('messages'),
      'conversation_id': c['id'],
      'sender_id': me,
      'body': text,
      'sent_at': MockDb.now(),
      'read_at': null,
    });
    // a new message brings the chat back for the other side if they had deleted it
    c[_isTenant(c, me) ? 'deleted_by_owner_at' : 'deleted_by_tenant_at'] = null;
  }

  Future<void> deleteForMe(int conversationId) async {
    final c = _mine(conversationId);
    final me = _db.currentUser['id'] as int;
    c[_isTenant(c, me) ? 'deleted_by_tenant_at' : 'deleted_by_owner_at'] = MockDb.now();
  }
}
