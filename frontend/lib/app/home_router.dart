import 'package:flutter/material.dart';

import '../core/app_services.dart';
import '../features/admin/admin_home_screen.dart';
import '../features/owner/screens/owner_shell.dart';
import '../features/student/screens/student_shell.dart';
import '../shared/models/user.dart';

/// เลือกหน้าหลักตาม role
Widget homeFor(AppServices services, CurrentUser user) {
  if (user.isAdmin) return AdminHomeScreen(services: services);
  if (user.isStudent) return StudentShell(services: services, user: user);
  return OwnerShell(services: services, user: user);
}
