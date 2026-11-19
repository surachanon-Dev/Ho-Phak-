import 'package:flutter/material.dart';

import '../core/app_services.dart';
import '../modules/admin/admin_home_screen.dart';
import '../modules/owner/shell/view/owner_shell.dart';
import '../modules/student/shell/view/student_shell.dart';
import '../model/user.dart';

/// เลือกหน้าหลักตาม role
Widget homeFor(AppServices services, CurrentUser user) {
  if (user.isAdmin) return AdminHomeScreen(services: services);
  if (user.isStudent) return StudentShell(services: services, user: user);
  return OwnerShell(services: services, user: user);
}
