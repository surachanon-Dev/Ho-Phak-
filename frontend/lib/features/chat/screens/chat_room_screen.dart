import 'package:flutter/material.dart';

import 'package:hopak_frontend/features/chat/controllers/chat_room_controller.dart';
import 'package:hopak_frontend/shared/models/chat.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/core/theme/app_theme.dart';
import 'package:hopak_frontend/core/utils/error_handling.dart';
import 'package:hopak_frontend/core/utils/format.dart';

/// ห้องแชท — หน้าตาตาม Figma O-7: หัวข้อสองบรรทัด (ชื่อ / "About ชื่อหอ"),
/// ฟองข้อความขาว (อีกฝ่าย) / น้ำเงิน (เรา) พร้อมเวลา, ช่องพิมพ์ทรงแคปซูล + ปุ่มส่งกลม
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
  late final ChatRoomController _c;

  @override
  void initState() {
    super.initState();
    _c = ChatRoomController(
      conversationId: widget.conversation.id,
      chats: widget.services.chats,
    );
    _c.addListener(_onChanged);
    _load();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _c.removeListener(_onChanged);
    _c.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final ok = await _c.load();
    if (!ok && mounted && _c.error != null) {
      showApiError(context, widget.services, _c.error!);
    }
  }

  Future<void> _send() async {
    final ok = await _c.send(_input.text);
    if (!mounted) return;
    if (ok) {
      _input.clear();
    } else if (_c.validationError != null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(_c.validationError!)),
      );
    } else if (_c.error != null) {
      showApiError(context, widget.services, _c.error!);
    }
  }

  /// เวลาของข้อความ (ข้อความของเราต่อท้าย Read เมื่ออีกฝ่ายอ่านแล้ว)
  String _stamp(ChatMessage m, bool mine) =>
      ChatRoomController.stampFor(m, mine: mine);

  /// วันที่ของข้อความ (ใช้ขึ้นหัวคั่นวัน)
  DateTime? _day(ChatMessage m) => ChatRoomController.dayOf(m);

  @override
  Widget build(BuildContext context) {
    final c = widget.conversation;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.asStudent ? 'Dorm owner' : 'Student #${c.tenantId}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            Text(
              'About ${c.dormitoryName}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: Column(
        children: [
          if (_c.readOnly)
            Container(
              width: double.infinity,
              color: AppColors.warningBg,
              padding: const EdgeInsets.all(8),
              child: const Text(
                'This chat is read-only because the dorm is suspended',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.warningText),
              ),
            ),
          Expanded(
            child: _c.loading
                ? const Center(child: CircularProgressIndicator())
                : _c.messages.isEmpty
                ? const Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: _c.messages.length,
                    itemBuilder: (context, i) {
                      final m = _c.messages[i];
                      final mine = m.senderId == widget.myUserId;
                      final day = _day(m);
                      final showDay =
                          i == 0 ||
                          (day != null && day != _day(_c.messages[i - 1]));
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showDay && day != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Center(
                                child: Text(
                                  relativeDay(m.sentAt),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          _Bubble(
                            text: m.body,
                            stamp: _stamp(m, mine),
                            mine: mine,
                          ),
                        ],
                      );
                    },
                  ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        enabled: !_c.readOnly,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: _c.readOnly
                              ? 'Can’t send messages'
                              : 'Type a message…',
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Send',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        fixedSize: const Size(48, 48),
                      ),
                      onPressed: (_c.readOnly || _c.sending) ? null : _send,
                      icon: const Icon(Icons.send_outlined),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ฟองข้อความ: อีกฝ่าย = ขาวชิดซ้าย, เรา = น้ำเงินตัวขาวชิดขวา + เวลาใต้ฟอง
class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.stamp, required this.mine});

  final String text;
  final String stamp;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: mine ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(mine ? 18 : 4),
                bottomRight: Radius.circular(mine ? 4 : 18),
              ),
              border: mine ? null : Border.all(color: AppColors.border),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: mine ? Colors.white : const Color(0xFF111827),
              ),
            ),
          ),
          if (stamp.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                stamp,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
