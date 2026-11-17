import 'package:flutter/material.dart';

import '../shared/models/user.dart';
import '../core/app_services.dart';
import '../features/admin/admin_home_screen.dart';
import '../features/owner/screens/owner_shell.dart';
import '../features/student/screens/student_shell.dart';

/// เลือกหน้าหลักตาม role: นักศึกษาไปโครงของนักศึกษา เจ้าของไปโครงของเจ้าของหอพัก
Widget homeFor(AppServices services, CurrentUser user) {
  if (user.isStudent) return StudentShell(services: services, user: user);
  if (user.isAdmin) return AdminHomeScreen(services: services);
  return OwnerShell(services: services, user: user);
}
