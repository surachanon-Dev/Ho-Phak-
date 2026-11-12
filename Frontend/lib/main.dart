import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'controllers/auth_controller.dart';
import 'controllers/badge_controller.dart';
import 'controllers/favorites_controller.dart';
import 'controllers/owner_controller.dart';
import 'services/admin_service.dart';
import 'services/auth_service.dart';
import 'services/chat_service.dart';
import 'services/dorm_service.dart';
import 'services/notification_service.dart';
import 'services/owner_service.dart';

/// Ho-Phak Frontend – MOCK MODE (data from lib/mock/mock_db.dart, same tables as the hopak database)
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        // Services (Model layer – mock now, HTTP later)
        Provider(create: (_) => DormService()),
        Provider(create: (_) => OwnerService()),
        Provider(create: (_) => AdminService()),
        Provider(create: (_) => ChatService()),
        Provider(create: (_) => NotificationService()),
        // Controllers (state used by the views)
        ChangeNotifierProvider(create: (_) => AuthController(AuthService())..init()),
        ChangeNotifierProvider(create: (_) => BadgeController(NotificationService(), ChatService())),
        ChangeNotifierProvider(create: (_) => FavoritesController(DormService())),
        ChangeNotifierProvider(create: (_) => OwnerController(OwnerService())),
      ],
      child: const HoPhakApp(),
    ),
  );
}
