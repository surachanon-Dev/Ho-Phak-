import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/badge_controller.dart';
import '../common/chat_list_view.dart';
import '../common/notifications_view.dart';

/// Chat + bell icons with unread badges (app bar of every role)
List<Widget> topActions(BuildContext context, {bool chat = true}) {
  final b = context.watch<BadgeController>();
  Future<void> open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (context.mounted) context.read<BadgeController>().refresh();
  }

  return [
    if (chat)
      IconButton(
        tooltip: 'ข้อความ',
        onPressed: () => open(const ChatListView()),
        icon: Badge(isLabelVisible: b.messages > 0, label: Text('${b.messages}'), child: const Icon(Icons.chat_bubble_outline)),
      ),
    IconButton(
      tooltip: 'การแจ้งเตือน',
      onPressed: () => open(const NotificationsView()),
      icon: Badge(isLabelVisible: b.notifications > 0, label: Text('${b.notifications}'), child: const Icon(Icons.notifications_none)),
    ),
    const SizedBox(width: 4),
  ];
}
