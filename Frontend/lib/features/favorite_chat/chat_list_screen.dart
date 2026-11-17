import 'package:flutter/material.dart';
import '../../../../ho_phak/lib/core/theme/app_colors.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

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
        valueListenable: ChatRoomScreen.chatUpdated,
        builder: (context, _, __) {
          final dormNames = ChatRoomScreen.chatHistories.keys.toList();

          if (dormNames.isEmpty) {
            return const Center(
              child: Text('No messages yet', style: TextStyle(color: AppColors.textSecondary)),
            );
          }

          return ListView.builder(
            itemCount: dormNames.length,
            itemBuilder: (context, index) {
              final dormName = dormNames[index].toString();
              final messages = ChatRoomScreen.chatHistories[dormName] as List;
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
                    ChatRoomScreen.chatHistories.remove(dormName);
                    ChatRoomScreen.chatUpdated.value++;
                  },
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChatRoomScreen(dormName: dormName)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}