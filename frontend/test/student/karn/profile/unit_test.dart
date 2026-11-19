// ผู้รับผิดชอบ: Karn (นักศึกษา)
// unit test: StudentBadgesController (ตัวเลขที่ยังไม่อ่าน) และการสมัครเป็นเจ้าของหอ
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:hopak_frontend/model/chat.dart';
import 'package:hopak_frontend/model/notification.dart';
import 'package:hopak_frontend/modules/student/profile/controller/student_badges_controller.dart';
import 'package:hopak_frontend/services/chat_service.dart';
import 'package:hopak_frontend/services/notification_service.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_backend.dart';
import '../../../helpers/student_data.dart';

class MockChatService extends Mock implements ChatService {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockChatService chats;
  late MockNotificationService notifications;
  late StudentBadgesController badges;

  setUp(() {
    chats = MockChatService();
    notifications = MockNotificationService();
    badges = StudentBadgesController(
      chats: chats,
      notifications: notifications,
    );
  });

  test('1. counts unread messages and notifications', () async {
    when(() => chats.conversations()).thenAnswer(
      (_) async => [
        Conversation.fromJson(conversationJson(id: 1, unread: 2)),
        Conversation.fromJson(conversationJson(id: 2, unread: 3)),
      ],
    );
    when(() => notifications.list()).thenAnswer(
      (_) async => [
        AppNotification.fromJson(notificationJson(id: 1)),
        AppNotification.fromJson(notificationJson(id: 2, read: true)),
      ],
    );

    await badges.refresh();

    expect(badges.messages, 5);
    expect(badges.notifications, 1);
  });

  test('2. load error keeps the old numbers without crashing', () async {
    // service จริงล้มแบบ Future ที่ error (ไม่ใช่ throw ทันที)
    when(() => chats.conversations())
        .thenAnswer((_) async => throw ApiException(500, 'down'));
    when(() => notifications.list())
        .thenAnswer((_) async => throw ApiException(500, 'down'));

    await badges.refresh();

    expect(badges.messages, 0);
    expect(badges.notifications, 0);
  });

  test('3. becomeOwner calls the backend and reloads the user', () async {
    final requests = <http.Request>[];
    final services = fakeBackend({
      'POST /api/me/become-owner': {'ok': true},
      'GET /api/me': {
        'user': {
          'id': 9,
          'role': 'owner',
          'status': 'active',
          'is_verified': 0,
        },
      },
    }, requests: requests);

    final user = await services.auth.becomeOwner();

    expect(requests.map((r) => '${r.method} ${r.url.path}'), [
      'POST /api/me/become-owner',
      'GET /api/me',
    ]);
    expect(user.isOwner, isTrue);
    expect(user.isVerified, isFalse);
  });
}
