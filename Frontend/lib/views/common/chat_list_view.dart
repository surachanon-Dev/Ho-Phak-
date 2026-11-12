import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/activity.dart';
import '../../services/chat_service.dart';
import '../widgets/common.dart';
import 'chat_view.dart';

/// conversations of the logged-in user (student ↔ owner)
class ChatListView extends StatefulWidget {
  const ChatListView({super.key});

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  late Future<List<Conversation>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ChatService>().conversations();
  }

  void _reload() => setState(() => _future = context.read<ChatService>().conversations());

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthController>().user!;
    return Scaffold(
      appBar: AppBar(title: const Text('ข้อความ')),
      body: FutureBuilder<List<Conversation>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return ErrorRetry(message: snap.error.toString(), onRetry: _reload);
          final items = snap.data!;
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.chat_bubble_outline,
              message: me.isStudent ? 'ยังไม่มีข้อความ\nกด "แชทกับเจ้าของ" ในหน้าหอพักเพื่อเริ่มคุย' : 'ยังไม่มีนักศึกษาทักมา',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final c = items[i];
              final other = me.id == c.tenantId ? c.ownerName : c.tenantName;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.teal.withValues(alpha: 0.15),
                    child: Text(other.isEmpty ? '?' : other.characters.first.toUpperCase(), style: const TextStyle(color: AppColors.teal)),
                  ),
                  title: Text(other, style: TextStyle(fontWeight: c.unread > 0 ? FontWeight.bold : FontWeight.w500)),
                  subtitle: Text('${c.dormName ?? 'หอพักถูกลบแล้ว'} · ${c.lastMessage ?? 'ยังไม่มีข้อความ'}',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(formatTime(c.lastAt), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    if (c.unread > 0) Badge(label: Text('${c.unread}')),
                  ]),
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => ChatView(conversationId: c.id)));
                    _reload();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
