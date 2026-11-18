import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/controller/owner/dormitory_controller.dart';
import 'package:hopak_frontend/controller/owner/local_owner_extras.dart';
import 'package:hopak_frontend/controller/owner/owner_account_controller.dart';
import 'package:hopak_frontend/controller/owner/owner_extras.dart';
import 'package:hopak_frontend/controller/owner/verification_controller.dart';
import 'package:hopak_frontend/services/api_client.dart';
import 'package:hopak_frontend/services/app_services.dart';
import 'package:hopak_frontend/services/auth_service.dart';
import 'package:hopak_frontend/services/chat_service.dart';
import 'package:hopak_frontend/services/favorite_service.dart';
import 'package:hopak_frontend/services/notification_service.dart';
import 'package:hopak_frontend/services/public_dormitory_service.dart';
import 'package:hopak_frontend/services/token_store.dart';
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
    dormitories = DormitoryController(api, extras);
    account = OwnerAccountController(extras);
    chats = ChatService(api);
    verification = VerificationController(api);
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
  late final DormitoryController dormitories;
  @override
  late final OwnerAccountController account;
  @override
  late final ChatService chats;
  @override
  late final VerificationController verification;
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
