import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/app_services.dart';
import 'admin/admin_home_screen.dart';
import 'home_shell.dart';
import 'student/student_shell.dart';

/// เลือกหน้าหลักตาม role: นักศึกษาไปโครงของนักศึกษา เจ้าของไปโครงของเจ้าของหอพัก
Widget homeFor(AppServices services, CurrentUser user) {
  if (user.isStudent) return StudentShell(services: services, user: user);
  if (user.isAdmin) return AdminHomeScreen(services: services);
  return HomeShell(services: services, user: user);
}
