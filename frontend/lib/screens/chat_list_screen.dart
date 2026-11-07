import 'package:flutter/material.dart';

import '../models/chat.dart';
import '../services/app_services.dart';
import '../ui/error_handling.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({
    super.key,
    required this.services,
    required this.myUserId,
    this.asStudent = false,
  });

  /// true เมื่อเป็นแชทของนักศึกษา (แสดงชื่อหอแทนเจ้าของ)
  final bool asStudent;

  final AppServices services;
  final int myUserId;

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Conversation> _items = [];
  String? _dormFilter;
  bool _loading = true;

  List<String> get _dormNames =>
      _items.map((c) => c.dormitoryName).toSet().toList();

  List<Conversation> get _visible => _dormFilter == null
      ? _items
      : _items.where((c) => c.dormitoryName == _dormFilter).toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await widget.services.chats.conversations();
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _confirmDelete(Conversation c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบแชทนี้?'),
        content: Text(
          'แชทกับนักศึกษาเกี่ยวกับ "${c.dormitoryName}" จะถูกลบจากรายการของคุณ '
          'อีกฝ่ายยังเห็นแชทนี้อยู่',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _delete(Conversation c) async {
    try {
      await widget.services.chats.delete(c.id);
      if (!mounted) return;
      setState(() => _items.removeWhere((x) => x.id == c.id));
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แชท'),
        actions: [
          IconButton(
            tooltip: 'รีเฟรช',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_items.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('ทั้งหมด'),
                    selected: _dormFilter == null,
                    onSelected: (_) => setState(() => _dormFilter = null),
                  ),
                  const SizedBox(width: 8),
                  for (final name in _dormNames) ...[
                    ChoiceChip(
                      label: Text(name),
                      selected: _dormFilter == name,
                      onSelected: (_) => setState(() => _dormFilter = name),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _load,
      child: _loading && _items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 120),
                Center(child: Text('ยังไม่มีแชท')),
                SizedBox(height: 8),
                Center(
                  child: Text(
                    'เมื่อนักศึกษาทักคุณเกี่ยวกับหอพัก จะแสดงที่นี่',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            )
          : ListView.separated(
              itemCount: _visible.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final c = _visible[i];
                return Dismissible(
                  key: ValueKey('conv-${c.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) => _confirmDelete(c),
                  onDismissed: (_) => _delete(c),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        widget.asStudent
                            ? (c.dormitoryName.isEmpty
                                  ? '?'
                                  : c.dormitoryName.characters.first)
                            : '${c.tenantId}',
                      ),
                    ),
                    title: Text(c.dormitoryName),
                    subtitle: Text(
                      c.lastMessage ?? 'ยังไม่มีข้อความ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: c.unreadCount > 0
                        ? CircleAvatar(
                            radius: 11,
                            backgroundColor: Colors.blue,
                            child: Text(
                              '${c.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          )
                        : null,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatRoomScreen(
                            services: widget.services,
                            conversation: c,
                            myUserId: widget.myUserId,
                            asStudent: widget.asStudent,
                          ),
                        ),
                      );
                      _load();
                    },
                  ),
                );
              },
            ),
    );
  }
}
