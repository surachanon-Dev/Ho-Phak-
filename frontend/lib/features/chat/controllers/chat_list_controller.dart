import 'package:flutter/foundation.dart';

import '../../../shared/models/chat.dart';
import '../services/chat_service.dart';

/// รายการแชท (ทั้งฝั่งเจ้าของและนักศึกษา): โหลด กรองตามหอ และลบออกจากรายการของเรา
class ChatListController extends ChangeNotifier {
  ChatListController(this._chats);

  final ChatService _chats;

  List<Conversation> _items = const [];
  String? _dormFilter;
  bool _loading = true;
  Object? _error;

  List<Conversation> get items => _items;
  bool get loading => _loading;
  Object? get error => _error;

  /// ชื่อหอที่ปรากฏในรายการ (ไม่ซ้ำ เรียงตามลำดับที่พบ)
  List<String> get dormNames =>
      _items.map((c) => c.dormitoryName).toSet().toList();

  /// ชื่อหอที่กรองอยู่ (null = ทุกหอ)
  String? get dormFilter => _dormFilter;

  /// รายการที่แสดงหลังกรอง
  List<Conversation> get visible => _dormFilter == null
      ? _items
      : _items.where((c) => c.dormitoryName == _dormFilter).toList();

  /// ตั้งตัวกรองหอ (ถ้าชื่อหอไม่มีในรายการจะถือเป็นทุกหอ)
  void setDormFilter(String? name) {
    _dormFilter = (name != null && dormNames.contains(name)) ? name : null;
    notifyListeners();
  }

  Future<bool> load() async {
    _loading = true;
    notifyListeners();
    try {
      _items = await _chats.conversations();
      _error = null;
      _dormFilter = (_dormFilter != null && dormNames.contains(_dormFilter))
          ? _dormFilter
          : null;
      return true;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// ลบแชทออกจากรายการของเรา (อีกฝ่ายยังเห็น) คืน true เมื่อสำเร็จ
  Future<bool> delete(int conversationId) async {
    try {
      await _chats.delete(conversationId);
      _items = _items.where((c) => c.id != conversationId).toList();
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      // โหลดใหม่เพื่อให้รายการตรงกับ backend หลังลบไม่สำเร็จ
      // (load จะล้าง error จึงต้องตั้งค่ากลับหลังโหลด)
      await load();
      _error = e;
      notifyListeners();
      return false;
    }
  }
}
