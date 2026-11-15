import 'package:flutter/material.dart';

import '../models/chat.dart';
import '../services/app_services.dart';
import '../ui/app_theme.dart';
import '../ui/error_handling.dart';
import '../ui/format.dart';
import 'chat_room_screen.dart';

/// รายการแชท (ใช้ทั้งฝั่ง owner และ student) — หน้าตาตาม Figma O-6:
/// หัวข้อใหญ่ + คำใบ้ปัดลบ + ชิปกรองตามหอ + การ์ดต่อแชท
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
        title: const Text('Delete this chat?'),
        content: Text(
          widget.asStudent
              ? 'The chat about "${c.dormitoryName}" will be removed from your list. '
                    'The owner will still see it.'
              : 'The chat with this student about "${c.dormitoryName}" will be removed from your list. '
                    'The student will still see it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                'Chat',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            if (_items.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: Text(
                  'Swipe a chat left to delete it',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    _DormChip(
                      label: 'All',
                      selected: _dormFilter == null,
                      onTap: () => setState(() => _dormFilter = null),
                    ),
                    for (final name in _dormNames) ...[
                      const SizedBox(width: 8),
                      _DormChip(
                        label: name,
                        selected: _dormFilter == name,
                        onTap: () => setState(() => _dormFilter = name),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            Expanded(child: _buildList()),
          ],
        ),
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
              children: [
                const SizedBox(height: 120),
                const Icon(
                  Icons.chat_bubble_outline,
                  size: 48,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'No chats yet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    widget.asStudent
                        ? 'Message a dorm owner from a dorm page to start a chat.'
                        : 'When a student messages you about a dorm, it will show up here.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              itemCount: _visible.length,
              itemBuilder: (context, i) {
                final c = _visible[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Dismissible(
                    key: ValueKey('conv-${c.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_outline, color: Colors.white),
                          SizedBox(height: 2),
                          Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    confirmDismiss: (_) => _confirmDelete(c),
                    onDismissed: (_) => _delete(c),
                    child: _ChatRow(
                      conversation: c,
                      asStudent: widget.asStudent,
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
                  ),
                );
              },
            ),
    );
  }
}

class _DormChip extends StatelessWidget {
  const _DormChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF111827),
            ),
          ),
        ),
      ),
    );
  }
}

/// การ์ดหนึ่งแชท: อวาตาร์ + ชื่อ + ชื่อหอ (น้ำเงิน) + ข้อความล่าสุด + เวลา/จำนวนยังไม่อ่าน
class _ChatRow extends StatelessWidget {
  const _ChatRow({
    required this.conversation,
    required this.asStudent,
    required this.onTap,
  });

  final Conversation conversation;
  final bool asStudent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    // API ไม่ส่งชื่อนักศึกษา จึงแสดงเป็นหมายเลขผู้ใช้
    final title = asStudent ? c.dormitoryName : 'Student #${c.tenantId}';
    final initials = asStudent
        ? (c.dormitoryName.isEmpty ? '?' : c.dormitoryName.characters.first)
        : '#${c.tenantId}';
    final time = chatTime(c.lastSentAt);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  initials,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (!asStudent)
                      Text(
                        c.dormitoryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      c.lastMessage ?? 'No messages yet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (time.isNotEmpty)
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  if (c.unreadCount > 0) ...[
                    const SizedBox(height: 6),
                    Container(
                      constraints: const BoxConstraints(minWidth: 22),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${c.unreadCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
