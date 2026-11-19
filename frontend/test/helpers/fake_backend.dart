// ตัวช่วยที่ widget test ใช้ร่วมกัน: backend ปลอม (ไม่ใช่ test เพราะไม่ได้ลงท้ายด้วย _test.dart)
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:hopak_frontend/core/network/token_store.dart';
import 'package:hopak_frontend/model/user.dart';
import 'package:hopak_frontend/services/api_owner_extras.dart';
import 'package:hopak_frontend/services/auth_service.dart';
import 'package:hopak_frontend/services/chat_service.dart';
import 'package:hopak_frontend/services/dormitory_service.dart';
import 'package:hopak_frontend/services/owner_extras.dart';
import 'package:hopak_frontend/services/verification_service.dart';
import 'package:hopak_frontend/services/favorite_service.dart';
import 'package:hopak_frontend/services/notification_service.dart';
import 'package:hopak_frontend/services/owner_account_service.dart';
import 'package:hopak_frontend/services/public_dormitory_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// AppServices ที่ทุก request วิ่งไปหา backend ปลอมแทน network จริง
/// service ทุกตัวเป็นของจริง ต่างกันแค่ ApiClient ที่ต่อกับ backend ปลอม
class FakeServices implements AppServices {
  FakeServices(this.api, this.tokens)
    : auth = AuthService(api, tokens),
      chats = ChatService(api),
      notifications = NotificationService(api),
      publicDorms = PublicDormitoryService(api),
      favorites = FavoriteService(api),
      extras = ApiOwnerExtras(api),
      verification = VerificationService(api) {
    account = OwnerAccountService(extras);
    dormitories = DormitoryService(api, extras);
  }

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
  final OwnerExtras extras;
  @override
  final VerificationService verification;
  @override
  late final OwnerAccountService account;
  @override
  late final DormitoryService dormitories;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// ผู้ใช้ที่ login อยู่ (ใช้กับหน้าที่ต้องรู้ว่าใครใช้งาน)
CurrentUser fakeUser({
  int id = 9,
  String role = 'student',
  String username = 'karn',
}) => CurrentUser(
  id: id,
  role: role,
  status: 'active',
  isVerified: false,
  username: username,
);

/// สร้าง backend ปลอม: [routes] คือ 'METHOD /path' → JSON ที่จะตอบกลับ
/// เช่น {'GET /api/admin/users': {'users': []}}
/// ถ้าต้องแยกตาม query ให้ใส่ query ในคีย์ได้ เช่น 'GET /api/admin/verifications?status=pending'
/// ถ้าคำตอบต้องเปลี่ยนตามสถานะ ให้ใส่เป็นฟังก์ชันได้ เช่น 'GET /api/admin/users': () => {...}
/// ทุก request ที่ยิงมาจะถูกเก็บใน [requests] เพื่อเช็กทีหลัง
FakeServices fakeBackend(
  Map<String, Object> routes, {
  List<http.Request>? requests,
}) {
  final client = MockClient((req) async {
    requests?.add(req);
    final key = '${req.method} ${req.url.path}';
    final route =
        (req.url.hasQuery ? routes['$key?${req.url.query}'] : null) ??
        routes[key];
    final body = route is Object Function() ? route() : route;
    // ตอบไฟล์ (เช่นเอกสาร PDF) ให้ใส่เป็น http.Response มาตรง ๆ
    if (body is http.Response) return body;
    if (body == null) return http.Response('{"message":"not mocked"}', 404);
    return http.Response(
      jsonEncode(body),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });
  addTearDown(client.close);
  final tokens = TokenStore();
  return FakeServices(
    ApiClient(tokenProvider: () => tokens.token, client: client),
    tokens,
  );
}

/// ไฟล์เอกสารปลอมสำหรับ endpoint ที่ส่งไฟล์กลับมา
http.Response fileResponse() => http.Response.bytes(
  List.filled(2048, 1),
  200,
  headers: {'content-type': 'application/pdf'},
);

/// ตั้งจอให้กว้างแบบ desktop (หน้าแอดมินออกแบบมาสำหรับจอกว้าง)
void useDesktopScreen(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1600, 1000);
  addTearDown(tester.view.reset);
}
