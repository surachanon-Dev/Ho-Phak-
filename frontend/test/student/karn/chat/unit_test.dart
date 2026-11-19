// ผู้รับผิดชอบ: Karn (นักศึกษา)
// unit test: ChatListController และ ChatRoomController (รายการแชท / ห้องแชท)
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:hopak_frontend/model/chat.dart';
import 'package:hopak_frontend/modules/chat/chat_list/controller/chat_list_controller.dart';
import 'package:hopak_frontend/modules/chat/chat_room/controller/chat_room_controller.dart';
import 'package:hopak_frontend/services/chat_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/student_data.dart';

class MockChatService extends Mock implements ChatService {}

void main() {
  late MockChatService chats;

  setUp(() {
    chats = MockChatService();
    when(() => chats.conversations()).thenAnswer(
      (_) async => [
        Conversation.fromJson(conversationJson(id: 1, dorm: 'Sunrise Dorm')),
        Conversation.fromJson(conversationJson(id: 2, dorm: 'Moon Dorm')),
        Conversation.fromJson(conversationJson(id: 3, dorm: 'Sunrise Dorm')),
      ],
    );
  });

  group('ChatListController', () {
    test(
      '1. load keeps the chats and the dorm names without repeats',
      () async {
        final c = ChatListController(chats);

        expect(await c.load(), isTrue);

        expect(c.items, hasLength(3));
        expect(c.dormNames, ['Sunrise Dorm', 'Moon Dorm']);
      },
    );

    test('2. dorm filter shows only the chats of that dorm', () async {
      final c = ChatListController(chats);
      await c.load();

      c.setDormFilter('Sunrise Dorm');
      expect(c.visible.map((x) => x.id), [1, 3]);

      c.setDormFilter('Unknown Dorm'); // ชื่อที่ไม่มี = ทุกหอ
      expect(c.visible, hasLength(3));
    });

    test('3. delete removes the chat from our list', () async {
      when(() => chats.delete(2)).thenAnswer((_) async {});
      final c = ChatListController(chats);
      await c.load();

      expect(await c.delete(2), isTrue);

      verify(() => chats.delete(2)).called(1);
      expect(c.items.map((x) => x.id), [1, 3]);
    });
  });

  group('ChatRoomController', () {
    late ChatRoomController room;

    void threadIs({bool readOnly = false}) {
      when(() => chats.thread(1)).thenAnswer(
        (_) async => ChatThread(
          messages: [ChatMessage.fromJson(messageJson())],
          readOnly: readOnly,
        ),
      );
    }

    setUp(() => room = ChatRoomController(conversationId: 1, chats: chats));

    test('4. load keeps the messages', () async {
      threadIs();

      expect(await room.load(), isTrue);

      expect(room.messages.single.body, 'Hello');
      expect(room.readOnly, isFalse);
    });

    test('5. send trims the text, posts it and reloads', () async {
      threadIs();
      when(() => chats.send(any(), any())).thenAnswer((_) async {});
      await room.load();

      expect(await room.send('  Is a room free?  '), isTrue);

      verify(() => chats.send(1, 'Is a room free?')).called(1);
      verify(() => chats.thread(1)).called(2); // โหลดครั้งแรก + หลังส่ง
    });

    test('6. empty or too long messages are not sent', () async {
      threadIs();
      await room.load();

      expect(await room.send('   '), isFalse);
      expect(await room.send('x' * 2001), isFalse);

      expect(room.validationError, isNotNull);
      verifyNever(() => chats.send(any(), any()));
    });

    test('7. read-only chat (dorm suspended) cannot send', () async {
      threadIs(readOnly: true);
      await room.load();

      expect(await room.send('Hello?'), isFalse);

      verifyNever(() => chats.send(any(), any()));
    });

    test('8. send that fails keeps the error', () async {
      threadIs();
      when(() => chats.send(any(), any()))
          .thenThrow(ApiException(403, 'Dorm suspended'));
      await room.load();

      expect(await room.send('Hello?'), isFalse);

      expect(room.error, isA<ApiException>());
      expect(room.sending, isFalse);
    });

    test('9. my message shows Read once the owner has read it', () {
      final read = ChatMessage.fromJson(
        messageJson(readAt: '2026-11-10T11:00:00Z'),
      );
      final unread = ChatMessage.fromJson(messageJson());

      expect(ChatRoomController.stampFor(read, mine: true), endsWith('Read'));
      expect(
        ChatRoomController.stampFor(unread, mine: true),
        isNot(contains('Read')),
      );
      expect(
        ChatRoomController.stampFor(read, mine: false),
        isNot(contains('Read')),
      );
    });
  });
}
