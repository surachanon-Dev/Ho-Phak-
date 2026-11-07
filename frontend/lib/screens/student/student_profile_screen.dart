import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../services/app_services.dart';
import '../login_screen.dart';
import '../notifications_screen.dart';

/// โปรไฟล์นักศึกษา: การแจ้งเตือน, ติดต่อแอดมิน และออกจากระบบ
/// หมายเหตุ: แก้ไขโปรไฟล์, รีวิวของฉัน และสมัครเป็นเจ้าของ ยังไม่มี API ใน TEST-API.js
class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({
    super.key,
    required this.services,
    required this.user,
  });

  final AppServices services;
  final CurrentUser user;

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ออกจากระบบ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
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
      MaterialPageRoute(builder: (_) => LoginScreen(services: services)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('โปรไฟล์')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(user.username ?? 'นักศึกษา #${user.id}'),
              subtitle: const Text('นักศึกษา'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('การแจ้งเตือน'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => NotificationsScreen(services: services),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.support_agent_outlined),
                  title: const Text('ติดต่อแอดมิน'),
                  subtitle: const Text(
                    'ช่องทางติดต่อยังไม่ได้กำหนด (รอการยืนยัน)',
                  ),
                  onTap: () => showDialog<void>(
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
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'ออกจากระบบ',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () => _logout(context),
            ),
          ),
        ],
      ),
    );
  }
}
