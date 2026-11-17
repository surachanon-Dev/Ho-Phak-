import 'package:flutter/material.dart';

import '../../../core/app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/user.dart';
import '../../../shared/widgets/ui/ui.dart';
import '../../auth/screens/welcome_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../owner/widgets/owner_ui.dart' show SettingsGroup;
import '../widgets/student_ui.dart';

/// โปรไฟล์นักศึกษา: การแจ้งเตือน, ติดต่อแอดมิน และออกจากระบบ
/// หมายเหตุ: แก้ไขโปรไฟล์, รีวิวของฉัน และสมัครเป็นเจ้าของ ยังไม่มี API สำหรับนักศึกษา
class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({
    super.key,
    required this.services,
    required this.user,
    this.actions,
  });

  final AppServices services;
  final CurrentUser user;

  /// ปุ่มบน app bar (แชท / แจ้งเตือน)
  final List<Widget>? actions;

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ออกจากระบบ?'),
        content: const Text('คุณต้องเข้าสู่ระบบใหม่เพื่อใช้งานต่อ'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await services.auth.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => WelcomeScreen(services: services)),
      (route) => false,
    );
  }

  void _contactAdmin(BuildContext context) => showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('ติดต่อแอดมิน'),
      content: const Text('เบอร์และอีเมลแอดมินยังไม่ได้กำหนด'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('ตกลง'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final name = user.username ?? 'นักศึกษา #${user.id}';
    return Scaffold(
      appBar: AppBar(title: const Text('โปรไฟล์'), actions: actions),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          StudentBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  child: Row(
                    children: [
                      InitialsAvatar(name: name, size: 56),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const ToneBadge(
                              label: 'นักศึกษา',
                              tone: Tone.primary,
                              icon: Icons.school_outlined,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SettingsGroup(
                  title: 'บัญชี',
                  children: [
                    ListTile(
                      leading: const IconBadge(
                        icon: Icons.notifications_none_rounded,
                        size: 36,
                      ),
                      title: const Text('การแจ้งเตือน'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              NotificationsScreen(services: services),
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const IconBadge(
                        icon: Icons.support_agent_rounded,
                        tone: Tone.info,
                        size: 36,
                      ),
                      title: const Text('ติดต่อแอดมิน'),
                      subtitle: const Text(
                        'ช่องทางติดต่อยังไม่ได้กำหนด (รอการยืนยัน)',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _contactAdmin(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SettingsGroup(
                  children: [
                    ListTile(
                      leading: const IconBadge(
                        icon: Icons.logout_rounded,
                        tone: Tone.danger,
                        size: 36,
                      ),
                      title: const Text(
                        'ออกจากระบบ',
                        style: TextStyle(color: AppColors.danger),
                      ),
                      onTap: () => _logout(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
