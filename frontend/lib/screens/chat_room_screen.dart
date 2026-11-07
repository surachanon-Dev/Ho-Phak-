import 'package:flutter/material.dart';

import '../models/chat.dart';
import '../services/app_services.dart';
import '../ui/error_handling.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({
    super.key,
    required this.services,
    required this.conversation,
    required this.myUserId,
    this.asStudent = false,
  });

  final bool asStudent;

  final AppServices services;
  final Conversation conversation;
  final int myUserId;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<ChatMessage> _messages = [];
  bool _readOnly = false;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final thread = await widget.services.chats.thread(widget.conversation.id);
      if (!mounted) return;
      setState(() {
        _messages = thread.messages;
        _readOnly = thread.readOnly;
      });
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _readOnly) return;
    if (text.length > 2000) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('ข้อความยาวเกิน 2000 ตัวอักษร')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.services.chats.send(widget.conversation.id, text);
      _input.clear();
      await _load();
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.conversation;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.asStudent ? 'เจ้าของหอพัก' : 'นักศึกษา #${c.tenantId}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'เกี่ยวกับ ${c.dormitoryName}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_readOnly)
            Container(
              width: double.infinity,
              color: Colors.amber.shade100,
              padding: const EdgeInsets.all(8),
              child: const Text(
                'แชทนี้อ่านได้อย่างเดียว เพราะหอพักถูกระงับ',
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? const Center(child: Text('ยังไม่มีข้อความ'))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      final mine = m.senderId == widget.myUserId;
                      return Align(
                        alignment: mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          constraints: const BoxConstraints(maxWidth: 280),
                          decoration: BoxDecoration(
                            color: mine
                                ? Colors.indigo.shade100
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(m.body),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      enabled: !_readOnly,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: _readOnly
                            ? 'ส่งข้อความไม่ได้'
                            : 'พิมพ์ข้อความ...',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'ส่ง',
                    onPressed: (_readOnly || _sending) ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
