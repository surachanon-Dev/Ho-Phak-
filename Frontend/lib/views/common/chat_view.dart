import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/activity.dart';
import '../../services/chat_service.dart';
import '../widgets/common.dart';

/// One conversation (messages table). Opening it marks the other side's messages as read.
class ChatView extends StatefulWidget {
  const ChatView({super.key, required this.conversationId});
  final int conversationId;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  Conversation? _conv;
  List<Message> _messages = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final service = context.read<ChatService>();
    try {
      final conv = await service.get(widget.conversationId);
      final msgs = await service.messages(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _conv = conv;
        _messages = msgs;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    }
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    if (body.isEmpty) return;
    _text.clear();
    await context.read<ChatService>().send(widget.conversationId, body);
    await _load();
  }

  Future<void> _delete() async {
    if (!await confirmDialog(context, 'ลบบทสนทนา', 'ลบบทสนทนานี้ออกจากรายการของคุณ? (อีกฝ่ายยังเห็นอยู่)', confirm: 'ลบ', danger: true)) return;
    if (!mounted) return;
    await context.read<ChatService>().deleteForMe(widget.conversationId);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthController>().user!;
    final c = _conv;
    final other = c == null ? '' : (me.id == c.tenantId ? c.ownerName : c.tenantName);
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(other),
          if (c?.dormName != null) Text(c!.dormName!, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ]),
        actions: [IconButton(tooltip: 'ลบบทสนทนา', onPressed: _delete, icon: const Icon(Icons.delete_outline))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorRetry(message: _error!, onRetry: _load)
              : Column(children: [
                  Expanded(
                    child: _messages.isEmpty
                        ? const EmptyState(icon: Icons.waving_hand_outlined, message: 'เริ่มทักทายได้เลย')
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.all(12),
                            itemCount: _messages.length,
                            itemBuilder: (_, i) {
                              final m = _messages[i];
                              final mine = m.senderId == me.id;
                              return Align(
                                alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  constraints: const BoxConstraints(maxWidth: 320),
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: mine ? AppColors.teal : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: mine ? null : Border.all(color: const Color(0xFFE0E6EC)),
                                  ),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                    Text(m.body, style: TextStyle(color: mine ? Colors.white : AppColors.text)),
                                    Text('${formatTime(m.sentAt)}${mine && m.readAt != null ? ' · อ่านแล้ว' : ''}',
                                        style: TextStyle(fontSize: 11, color: mine ? Colors.white70 : AppColors.muted)),
                                  ]),
                                ),
                              );
                            },
                          ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                      child: Row(children: [
                        Expanded(
                          child: TextField(
                            controller: _text,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            decoration: const InputDecoration(hintText: 'พิมพ์ข้อความ...'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(onPressed: _send, icon: const Icon(Icons.send)),
                      ]),
                    ),
                  ),
                ]),
    );
  }
}
