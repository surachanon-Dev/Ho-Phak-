import 'package:flutter/material.dart';
import '../../../../ho_phak/lib/core/theme/app_colors.dart';

class ChatRoomScreen extends StatefulWidget {
  final String dormName;
  const ChatRoomScreen({super.key, required this.dormName});

  static final ValueNotifier<int> chatUpdated = ValueNotifier<int>(0);
  // Starts empty; only displays dormitories that the user actually opens to chat
  static final Map<String, List > chatHistories = {};

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _msgController = TextEditingController();
  late List _messages;

  @override
  void initState() {
    super.initState();
    if (!ChatRoomScreen.chatHistories.containsKey(widget.dormName)) {
      ChatRoomScreen.chatHistories[widget.dormName] = [
        {'isMe': true, 'text': 'Hello, I am interested in a monthly room.'},
        {'isMe': false, 'text': 'Hello! We currently have an available room on the 3rd floor. Would you like to schedule a viewing?'},
      ];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ChatRoomScreen.chatUpdated.value++;
      });
    }
    _messages = ChatRoomScreen.chatHistories[widget.dormName]!;
  }

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'isMe': true, 'text': text});
      _msgController.clear();
    });
    ChatRoomScreen.chatUpdated.value++;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.dormName),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final isMe = _messages[index]['isMe'] == true;
                final text = _messages[index]['text'].toString();

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      text,
                      style: TextStyle(color: isMe ? Colors.white : AppColors.textPrimary),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primary),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}