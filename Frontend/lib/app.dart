import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'core/theme.dart';
import 'views/admin/admin_shell.dart';
import 'views/auth/login_view.dart';
import 'views/auth/splash_view.dart';
import 'views/owner/owner_shell.dart';
import 'views/student/student_shell.dart';

class HoPhakApp extends StatelessWidget {
  const HoPhakApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Ho-Phak',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const RoleGate(),
      );
}

/// Opens the part of the app that matches users.role
class RoleGate extends StatelessWidget {
  const RoleGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    if (auth.initializing) return const SplashView();
    final user = auth.user;
    if (user == null) return const LoginView();
    // KeyedSubtree: switching user rebuilds the whole area with fresh state
    return KeyedSubtree(
      key: ValueKey(user.id),
      child: switch (user.role) {
        'owner' => const OwnerShell(),
        'admin' => const AdminShell(),
        _ => const StudentShell(),
      },
    );
  }
}
