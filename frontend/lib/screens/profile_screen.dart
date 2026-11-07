import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/app_services.dart';
import 'login_screen.dart';
import 'my_reviews_screen.dart';
import 'notifications_screen.dart';
import 'verification_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.services, required this.user});

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
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(user.username ?? 'เจ้าของหอพัก #${user.id}'),
              subtitle: const Text('Dorm owner'),
              trailing: user.isVerified
                  ? const Chip(label: Text('ยืนยันแล้ว'))
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: const Text('My verification'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VerificationScreen(services: services),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.star_outline),
                  title: const Text('My reviews'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MyReviewsScreen(services: services),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notification settings'),
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
                  title: const Text('Help / Contact admin'),
                  subtitle: const Text(
                    'ช่องทางติดต่อยังไม่ได้กำหนด (รอการยืนยัน)',
                  ),
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Help / Contact admin'),
                      content: const Text(
                        'หากหอพักถูกปฏิเสธหรือระงับ หรือมีปัญหาเกี่ยวกับบัญชี '
                        'กรุณาติดต่อแอดมิน (เบอร์และอีเมลยังไม่ได้กำหนด)',
                      ),
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
