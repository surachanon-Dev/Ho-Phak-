import 'package:flutter/material.dart';

import 'package:hopak_frontend/shared/models/user.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/features/admin/screens/home_screen.dart';
import 'package:hopak_frontend/features/owner/screens/owner_shell.dart';
import 'package:hopak_frontend/features/student/screens/student_shell.dart';

/// เลือกหน้าหลักตาม role: นักศึกษาไปโครงของนักศึกษา เจ้าของไปโครงของเจ้าของหอพัก
Widget homeFor(AppServices services, CurrentUser user) {
  if (user.isStudent) return StudentShell(services: services, user: user);
  if (user.isAdmin) return AdminHomeScreen(services: services);
  return OwnerShell(services: services, user: user);
}
