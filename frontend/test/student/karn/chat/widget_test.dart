// ผู้รับผิดชอบ: Karn (นักศึกษา)
// widget test: หน้ารายการแชทและห้องแชท
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/model/chat.dart';
import 'package:hopak_frontend/modules/chat/chat_list/view/chat_list_screen.dart';
import 'package:hopak_frontend/modules/chat/chat_room/view/chat_room_screen.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/fake_backend.dart';
import '../../../helpers/student_data.dart';

Future<void> openList(WidgetTester tester, AppServices services) async {
  useDesktopScreen(tester);
  await tester.pumpWidget(
    MaterialApp(
      home: ChatListScreen(services: services, myUserId: 9, asStudent: true),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> openRoom(
  WidgetTester tester,
  AppServices services, {
  String dormStatus = 'published',
}) async {
  useDesktopScreen(tester);
  await tester.pumpWidget(
    MaterialApp(
      home: ChatRoomScreen(
        services: services,
        conversation: Conversation.fromJson(
          conversationJson(dormStatus: dormStatus),
        ),
        myUserId: 9,
        asStudent: true,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('1. Chat list shows the dorm and the last message', (
    tester,
  ) async {
    await openList(
      tester,
      fakeBackend({
        'GET /api/conversations': {
          'conversations': [conversationJson(dorm: 'Sunrise Dorm')],
        },
      }),
    );

    expect(find.text('Sunrise Dorm'), findsWidgets);
    expect(find.text('Is there a room left?'), findsOneWidget);
  });

  testWidgets('2. No chats shows how to start one', (tester) async {
    await openList(
      tester,
      fakeBackend({
        'GET /api/conversations': {'conversations': []},
      }),
    );

    expect(find.text('No chats yet'), findsOneWidget);
  });

  testWidgets('3. Dorm filter shows only the chats of that dorm', (
    tester,
  ) async {
    await openList(
      tester,
      fakeBackend({
        'GET /api/conversations': {
          'conversations': [
            conversationJson(id: 1, dorm: 'Sunrise Dorm', last: 'Hi Sunrise'),
            conversationJson(id: 2, dorm: 'Moon Dorm', last: 'Hi Moon'),
          ],
        },
      }),
    );
    expect(find.text('Hi Sunrise'), findsOneWidget);

    await tester.tap(find.text('Moon Dorm').first); // ชิปตัวกรองอยู่ก่อนรายการ
    await tester.pumpAndSettle();

    expect(find.text('Hi Moon'), findsOneWidget);
    expect(find.text('Hi Sunrise'), findsNothing);
  });

  testWidgets('4. Chat room shows the messages and sends a new one', (
    tester,
  ) async {
    final requests = <http.Request>[];
    await openRoom(
      tester,
      fakeBackend({
        'GET /api/conversations/1/messages': {
          'messages': [messageJson(body: 'Hello, is a room free?')],
          'read_only': false,
        },
        'POST /api/conversations/1/messages': {'ok': true},
      }, requests: requests),
    );
    expect(find.text('About Sunrise Dorm'), findsOneWidget);
    expect(find.text('Hello, is a room free?'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '  How much is water?  ');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    final post = requests.where((r) => r.method == 'POST').single;
    expect(jsonDecode(post.body), {'body': 'How much is water?'});
  });

  testWidgets('6. Chat list opened from home has a working Back button', (
    tester,
  ) async {
    useDesktopScreen(tester);
    final services = fakeBackend({
      'GET /api/conversations': {'conversations': []},
    });
    // จำลองหน้าแรกที่กดไอคอนแชทแล้วเปิดหน้ารายการแชททับ
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ChatListScreen(
                    services: services,
                    myUserId: 9,
                    asStudent: true,
                  ),
                ),
              ),
              child: const Text('Home page'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Home page'));
    await tester.pumpAndSettle();
    expect(find.text('Chat'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Chat'), findsNothing);
    expect(find.text('Home page'), findsOneWidget);
  });

  testWidgets('7. Chat list used as a tab has no Back button', (tester) async {
    await openList(
      tester,
      fakeBackend({
        'GET /api/conversations': {'conversations': []},
      }),
    );

    expect(find.byTooltip('Back'), findsNothing);
  });

  testWidgets('5. Chat of a suspended dorm is read-only', (tester) async {
    await openRoom(
      tester,
      fakeBackend({
        'GET /api/conversations/1/messages': {
          'messages': [],
          'read_only': true,
        },
      }),
      dormStatus: 'suspended',
    );

    expect(
      find.text('This chat is read-only because the dorm is suspended'),
      findsOneWidget,
    );
    expect(find.text('Can’t send messages'), findsOneWidget);
  });
}
