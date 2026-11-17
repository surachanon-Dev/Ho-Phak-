import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'chat_view.dart';

class ChatListView extends StatelessWidget {
  const ChatListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Messages'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: ChatView.chatUpdated,
        builder: (context, _, __) {
          final dormNames = ChatView.chatHistories.keys.toList();

          if (dormNames.isEmpty) {
            return const Center(
              child: Text('No messages yet', style: TextStyle(color: AppColors.textSecondary)),
            );
          }

          return ListView.builder(
            itemCount: dormNames.length,
            itemBuilder: (context, index) {
              final dormName = dormNames[index];
              final messages = ChatView.chatHistories[dormName] ?? [];
              final lastMessage = messages.isNotEmpty
                  ? messages.last['text'].toString()
                  : 'Start a conversation...';

              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.support_agent, color: Colors.white),
                ),
                title: Text(dormName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () {
                    ChatView.chatHistories.remove(dormName);
                    ChatView.chatUpdated.value++;
                  },
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChatView(dormName: dormName)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}