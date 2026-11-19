import 'package:flutter/foundation.dart';

import '../../../../model/chat.dart';
import '../../../../services/chat_service.dart';
import '../../../../core/utils/format.dart';

/// ห้องแชท: โหลดข้อความ ส่งข้อความ และคำนวณข้อความแสดงเวลา/อ่านแล้ว
class ChatRoomController extends ChangeNotifier {
  ChatRoomController({required this.conversationId, required ChatService chats})
    : _chats = chats;

  static const maxMessageLength = 2000;

  final int conversationId;
  final ChatService _chats;

  List<ChatMessage> _messages = const [];
  bool _readOnly = false;
  bool _loading = true;
  bool _sending = false;
  Object? _error;
  String? _validationError;

  List<ChatMessage> get messages => _messages;

  /// true เมื่อหอถูกระงับ ห้ามส่งข้อความ
  bool get readOnly => _readOnly;
  bool get loading => _loading;
  bool get sending => _sending;

  /// error จาก API ให้หน้าจอแสดงด้วย showApiError
  Object? get error => _error;

  /// ข้อความผิดพลาดฝั่งผู้ใช้ เช่น ข้อความยาวเกินกำหนด (ไม่ยิง API)
  String? get validationError => _validationError;

  /// โหลดข้อความ คืน true เมื่อสำเร็จ
  Future<bool> load() async {
    try {
      final thread = await _chats.thread(conversationId);
      _messages = thread.messages;
      _readOnly = thread.readOnly;
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

  /// ส่งข้อความ (ตัดช่องว่างหัวท้าย) คืน true เมื่อส่งสำเร็จและโหลดข้อความใหม่แล้ว
  /// ข้อความว่าง, ห้องที่อ่านได้อย่างเดียว, หรือยาวเกินกำหนดจะไม่ยิง API
  Future<bool> send(String raw) async {
    final text = raw.trim();
    _validationError = null;
    if (text.isEmpty || _readOnly || _sending) return false;
    if (text.length > maxMessageLength) {
      _validationError = 'Messages can be at most $maxMessageLength characters';
      notifyListeners();
      return false;
    }
    _sending = true;
    notifyListeners();
    try {
      await _chats.send(conversationId, text);
      _error = null;
      await load();
      return true;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  /// เวลาของข้อความ "HH:mm" (ข้อความของเราต่อท้าย " · Read" เมื่ออีกฝ่ายอ่านแล้ว)
  static String stampFor(ChatMessage m, {required bool mine}) {
    final t = DateTime.tryParse(m.sentAt);
    final base = t == null ? '' : hhmm(t.toLocal());
    if (mine && m.readAt != null) return base.isEmpty ? 'Read' : '$base · Read';
    return base;
  }

  /// วันของข้อความ (ใช้หัวคั่นวัน) null ถ้าอ่านเวลาไม่ได้
  static DateTime? dayOf(ChatMessage m) {
    final t = DateTime.tryParse(m.sentAt)?.toLocal();
    return t == null ? null : DateTime(t.year, t.month, t.day);
  }
}
