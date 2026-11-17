import '../models/chat.dart';
import 'api_client.dart';

class ChatService {
  ChatService(this._api);

  final ApiClient _api;

  /// GET /api/conversations → { conversations: [...] }
  Future<List<Conversation>> conversations() async {
    final data = await _api.get('/api/conversations') as Map<String, dynamic>;
    return (data['conversations'] as List)
        .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/conversations { dormitory_id } (นักศึกษา) → { id } เปิดแชทเดิมถ้ามีแล้ว
  Future<int> open(int dormitoryId) async {
    final data = await _api.post('/api/conversations', {
      'dormitory_id': dormitoryId,
    }) as Map<String, dynamic>;
    return (data['id'] as num).toInt();
  }

  /// GET /api/conversations/:id/messages → { messages, read_only }
  Future<ChatThread> thread(int conversationId) async {
    final data = await _api.get(
      '/api/conversations/$conversationId/messages',
    ) as Map<String, dynamic>;
    return ChatThread(
      messages: (data['messages'] as List)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      readOnly: data['read_only'] == true,
    );
  }

  /// POST /api/conversations/:id/messages { body } (1–2000 ตัว)
  /// หอถูกระงับ/ถูกลบ → 403
  Future<void> send(int conversationId, String body) =>
      _api.post('/api/conversations/$conversationId/messages', {'body': body});

  /// DELETE /api/conversations/:id ลบจากรายการของเราเท่านั้น อีกฝ่ายยังเห็น
  Future<void> delete(int conversationId) =>
      _api.delete('/api/conversations/$conversationId');
}
