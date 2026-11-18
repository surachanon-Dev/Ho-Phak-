// ผู้รับผิดชอบ: Plub (Tester)
// backend ปลอมสำหรับเทสต์หน้า Sign In / Sign Up: บันทึกทุก request ไว้ตรวจได้
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:hopak_frontend/core/network/token_store.dart';
import 'package:hopak_frontend/features/auth/services/auth_service.dart';
import 'package:hopak_frontend/features/chat/services/chat_service.dart';
import 'package:hopak_frontend/features/notifications/services/notification_service.dart';
import 'package:hopak_frontend/features/owner/services/dormitory_service.dart';
import 'package:hopak_frontend/features/owner/services/local_owner_extras.dart';
import 'package:hopak_frontend/features/owner/services/owner_account_service.dart';
import 'package:hopak_frontend/features/owner/services/owner_extras.dart';
import 'package:hopak_frontend/features/owner/services/verification_service.dart';
import 'package:hopak_frontend/features/student/services/favorite_service.dart';
import 'package:hopak_frontend/features/student/services/public_dormitory_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Fake backend: every request goes to [handler] instead of the network.
typedef FakeBackend = Future<http.Response> Function(http.Request request);

/// Same wiring as AppServices, but the ApiClient talks to a MockClient.
/// Every request is recorded in [requests] so tests can check what was sent.
class FakeServices implements AppServices {
  FakeServices(FakeBackend handler) {
    final client = MockClient((request) async {
      requests.add(request);
      return handler(request);
    });
    addTearDown(client.close);
    tokens = TokenStore();
    api = ApiClient(tokenProvider: () => tokens.token, client: client);
    auth = AuthService(api, tokens);
    extras = LocalOwnerExtras(userId: () => auth.userId);
    dormitories = DormitoryService(api, extras);
    account = OwnerAccountService(extras);
    chats = ChatService(api);
    verification = VerificationService(api);
    notifications = NotificationService(api);
    publicDorms = PublicDormitoryService(api);
    favorites = FavoriteService(api);
  }

  final List<http.Request> requests = [];

  /// Requests sent to [path] (e.g. '/api/login')
  List<http.Request> to(String path) => requests.where((r) => r.url.path == path).toList();

  /// JSON body of the last request sent to [path]
  Map<String, dynamic> bodyOf(String path) => jsonDecode(to(path).last.body) as Map<String, dynamic>;

  @override
  late final TokenStore tokens;
  @override
  late final ApiClient api;
  @override
  late final AuthService auth;
  @override
  late final OwnerExtras extras;
  @override
  late final DormitoryService dormitories;
  @override
  late final OwnerAccountService account;
  @override
  late final ChatService chats;
  @override
  late final VerificationService verification;
  @override
  late final NotificationService notifications;
  @override
  late final PublicDormitoryService publicDorms;
  @override
  late final FavoriteService favorites;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

http.Response json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// GET /api/me response
Map<String, dynamic> me({String role = 'student', String status = 'active', int id = 20}) => {
  'user': {'id': id, 'username': 'qa_$role', 'role': role, 'status': status, 'is_verified': 1},
};

/// Phone-sized screen, tall enough that the whole form fits
void usePhoneScreen(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(430, 1400);
  addTearDown(tester.view.reset);
}

/// The TextField inside the n-th TextFormField on the page
TextField textFieldAt(WidgetTester tester, int index) => tester.widget<TextField>(
  find.descendant(of: find.byType(TextFormField).at(index), matching: find.byType(TextField)),
);

Finder fieldAt(int index) => find.byType(TextFormField).at(index);

/// Empty answer for any page the app opens after login (lists, counts …)
Future<http.Response> emptyAnswer(http.Request request) async =>
    json({'items': [], 'dormitories': [], 'favorites': [], 'conversations': [], 'notifications': []});
