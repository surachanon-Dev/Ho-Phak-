import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:hophak_frontend/controllers/auth_controller.dart';
import 'package:hophak_frontend/controllers/badge_controller.dart';
import 'package:hophak_frontend/controllers/favorites_controller.dart';
import 'package:hophak_frontend/controllers/owner_controller.dart';
import 'package:hophak_frontend/services/admin_service.dart';
import 'package:hophak_frontend/services/auth_service.dart';
import 'package:hophak_frontend/services/chat_service.dart';
import 'package:hophak_frontend/services/dorm_service.dart';
import 'package:hophak_frontend/services/notification_service.dart';
import 'package:hophak_frontend/services/owner_service.dart';

/// Same providers as lib/main.dart (MOCK MODE)
Widget withProviders(Widget child, {bool initAuth = false}) => MultiProvider(
      providers: [
        Provider(create: (_) => DormService()),
        Provider(create: (_) => OwnerService()),
        Provider(create: (_) => AdminService()),
        Provider(create: (_) => ChatService()),
        Provider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) {
          final c = AuthController(AuthService());
          if (initAuth) c.init();
          return c;
        }),
        ChangeNotifierProvider(create: (_) => BadgeController(NotificationService(), ChatService())),
        ChangeNotifierProvider(create: (_) => FavoritesController(DormService())),
        ChangeNotifierProvider(create: (_) => OwnerController(OwnerService())),
      ],
      child: child,
    );

/// Wrap one page so it can be tested on its own
Widget page(Widget child) => withProviders(MaterialApp(home: child));

/// Wrap a widget that is not a full page (e.g. DormCard, SearchView)
Widget inScaffold(Widget child) => withProviders(MaterialApp(home: Scaffold(body: child)));

/// Tall screen so long forms fit without scrolling
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Wait for the mock's fake network delay (MockDb.delay) and all animations
Future<void> settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

/// The AuthController that the page under test is using
AuthController authOf(WidgetTester tester, Finder anyWidgetInTree) =>
    Provider.of<AuthController>(tester.element(anyWidgetInTree), listen: false);

/// Text typed into a TextFormField / TextField found by key
String textOf(WidgetTester tester, Key key) =>
    tester.widget<EditableText>(find.descendant(of: find.byKey(key), matching: find.byType(EditableText))).controller.text;
