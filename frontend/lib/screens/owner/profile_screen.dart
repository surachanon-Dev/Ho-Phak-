import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../services/app_services.dart';
import '../../ui/app_theme.dart';
import '../login_screen.dart';
import '../notifications_screen.dart';
import 'my_reviews_screen.dart';
import 'verification_screen.dart';

/// แท็บ Profile ของเจ้าของ
/// ข้อมูลที่ API ให้มีแค่ username และสถานะยืนยัน (GET /api/me)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.services, required this.user});

  final AppServices services;
  final CurrentUser user;

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign out'),
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

  void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final name = user.username ?? 'Dorm owner #${user.id}';
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const Center(
              child: Text(
                'Profile',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 44,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: user.isVerified
                      ? AppColors.primarySoft
                      : AppColors.warningBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  user.isVerified ? 'Verified owner' : 'Not verified',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: user.isVerified
                        ? AppColors.primary
                        : AppColors.warningText,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Column(
                children: [
                  _Row(
                    icon: Icons.verified_user_outlined,
                    label: 'My verification',
                    onTap: () => _push(
                      context,
                      VerificationScreen(services: services),
                    ),
                  ),
                  const Divider(height: 1),
                  _Row(
                    icon: Icons.star_outline,
                    label: 'My reviews',
                    onTap: () =>
                        _push(context, MyReviewsScreen(services: services)),
                  ),
                  const Divider(height: 1),
                  _Row(
                    icon: Icons.notifications_outlined,
                    label: 'Notification settings',
                    onTap: () => _push(
                      context,
                      NotificationsScreen(services: services),
                    ),
                  ),
                  const Divider(height: 1),
                  _Row(
                    icon: Icons.help_outline,
                    label: 'Help / Contact admin',
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Help / Contact admin'),
                        content: const Text(
                          'If your dorm is rejected or suspended, or you have '
                          'a problem with your account, please contact the '
                          'admin. The admin phone number has not been set yet '
                          '(to be confirmed).',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: _Row(
                icon: Icons.logout,
                label: 'Sign out',
                color: AppColors.danger,
                showChevron: false,
                onTap: () => _logout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.showChevron = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF111827);
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xFF4B5563)),
      title: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w600, color: c),
      ),
      trailing: showChevron
          ? const Icon(Icons.chevron_right, color: Color(0xFF4B5563))
          : null,
      onTap: onTap,
    );
  }
}
