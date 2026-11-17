// services ปลอมสำหรับเทสต์ widget ของนักศึกษา: ใช้บริการจริง (ทุกตัวเรียก API ผ่าน MockClient)
// ส่วนที่ไม่ได้ใช้จะ throw ถ้าถูกเรียก
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:hopak_frontend/core/network/token_store.dart';
import 'package:hopak_frontend/features/auth/services/auth_service.dart';
import 'package:hopak_frontend/features/chat/services/chat_service.dart';
import 'package:hopak_frontend/features/notifications/services/notification_service.dart';
import 'package:hopak_frontend/features/student/services/favorite_service.dart';
import 'package:hopak_frontend/features/student/services/public_dormitory_service.dart';
import 'package:http/testing.dart';

import 'admin_test_helpers.dart';

class StudentTestServices implements AppServices {
  StudentTestServices(this.api, this.tokens)
      : auth = AuthService(api, tokens),
        chats = ChatService(api),
        notifications = NotificationService(api),
        publicDorms = PublicDormitoryService(api),
        favorites = FavoriteService(api);

  @override
  final ApiClient api;

  @override
  final TokenStore tokens;

  @override
  final AuthService auth;

  @override
  final ChatService chats;

  @override
  final NotificationService notifications;

  @override
  final PublicDormitoryService publicDorms;

  @override
  final FavoriteService favorites;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// services ที่ทุก request วิ่งไปที่ [handler] (ไม่มี network จริง)
StudentTestServices studentServicesWith(RequestHandler handler) {
  final client = MockClient(handler);
  final tokens = TokenStore();
  return StudentTestServices(
    ApiClient(tokenProvider: () => tokens.token, client: client),
    tokens,
  );
}

