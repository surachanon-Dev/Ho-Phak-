// ผู้รับผิดชอบ: Karn (นักศึกษา)
// unit test: NotificationsController (การแจ้งเตือน)
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:hopak_frontend/model/notification.dart';
import 'package:hopak_frontend/modules/notifications/controller/notifications_controller.dart';
import 'package:hopak_frontend/services/notification_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/student_data.dart';

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockNotificationService service;
  late NotificationsController controller;

  final unread = AppNotification.fromJson(notificationJson(id: 1));
  final read = AppNotification.fromJson(notificationJson(id: 2, read: true));

  setUp(() {
    service = MockNotificationService();
    controller = NotificationsController(service);
    when(() => service.list()).thenAnswer((_) async => [unread, read]);
  });

  test('1. load keeps the list and counts the unread ones', () async {
    expect(await controller.load(), isTrue);

    expect(controller.items, hasLength(2));
    expect(controller.unreadCount, 1);
  });

  test('2. opening an unread notification marks it as read', () async {
    when(() => service.markRead(1)).thenAnswer((_) async {});

    expect(await controller.open(unread), isTrue);

    verify(() => service.markRead(1)).called(1);
    verify(() => service.list()).called(1); // โหลดใหม่ให้ตรงกับ backend
  });

  test('3. opening a read notification does not mark it again', () async {
    expect(await controller.open(read), isTrue);

    verifyNever(() => service.markRead(any()));
  });

  test('4. mark as read that fails returns false with the error', () async {
    when(() => service.markRead(1)).thenThrow(ApiException(500, 'down'));

    expect(await controller.open(unread), isFalse);

    expect(controller.error, isA<ApiException>());
  });
}
