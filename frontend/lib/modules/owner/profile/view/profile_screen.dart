import 'package:flutter/material.dart';

import '../../../shared/models/user.dart';
import '../../../core/app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/screens/login_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'my_reviews_screen.dart';
import 'notification_settings_screen.dart';
import 'verification_screen.dart';
import '../controllers/owner_profile_controller.dart';
import '../../../shared/widgets/ui/ui.dart';
import '../widgets/owner_ui.dart';

/// แท็บ Profile ของเจ้าของ
/// ข้อมูลที่ API ให้มีแค่ username และสถานะยืนยัน (GET /api/me)
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.services, required this.user});

  final AppServices services;
  final CurrentUser user;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppServices get services => widget.services;
  CurrentUser get user => widget.user;
  late final OwnerProfileController _c;

  @override
  void initState() {
    super.initState();
    _c = OwnerProfileController(
      account: services.account,
      auth: services.auth,
      fallbackName: user.username,
    );
    _c.addListener(() {
      if (mounted) setState(() {});
    });
    _c.load();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _editProfile(BuildContext context) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            EditProfileScreen(services: services, profile: _c.profile),
      ),
    );
    if (saved == true) _c.load();
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const IconBadge(
          icon: Icons.logout_rounded,
          tone: Tone.danger,
          size: 48,
        ),
        title: const Text('Sign out?', textAlign: TextAlign.center),
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
    await _c.logout();
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
    final saved = _c.profile.fullName;
    final name = saved.isNotEmpty
        ? saved
        : (user.username ?? 'Dorm owner #${user.id}');
    final phone = _c.profile.phone;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            OwnerBody(
              maxWidth: 620,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---- หัวโปรไฟล์ ----
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: ProfileAvatar(
                            photoBase64: _c.profile.photoBase64,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        if (phone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            phone,
                            style: const TextStyle(color: Color(0xD9FFFFFF)),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: user.isVerified
                                ? Colors.white
                                : AppColors.warningBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                user.isVerified
                                    ? Icons.verified_rounded
                                    : Icons.error_outline_rounded,
                                size: 14,
                                color: user.isVerified
                                    ? AppColors.primary
                                    : AppColors.warningText,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                user.isVerified
                                    ? 'Verified owner'
                                    : 'Not verified',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: user.isVerified
                                      ? AppColors.primary
                                      : AppColors.warningText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SettingsGroup(
                    title: 'Account',
                    children: [
                      _Row(
                        icon: Icons.edit_outlined,
                        label: 'Edit profile',
                        onTap: () => _editProfile(context),
                      ),
                      _Row(
                        icon: Icons.lock_outline,
                        label: 'Change password',
                        tone: Tone.violet,
                        onTap: () => _push(
                          context,
                          ChangePasswordScreen(services: services),
                        ),
                      ),
                      _Row(
                        icon: Icons.verified_user_outlined,
                        label: 'My verification',
                        tone: Tone.success,
                        onTap: () => _push(
                          context,
                          VerificationScreen(services: services),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SettingsGroup(
                    title: 'Activity',
                    children: [
                      _Row(
                        icon: Icons.star_outline,
                        label: 'My reviews',
                        tone: Tone.warning,
                        onTap: () =>
                            _push(context, MyReviewsScreen(services: services)),
                      ),
                      _Row(
                        icon: Icons.notifications_outlined,
                        label: 'Notification settings',
                        tone: Tone.info,
                        onTap: () => _push(
                          context,
                          NotificationSettingsScreen(services: services),
                        ),
                      ),
                      _Row(
                        icon: Icons.help_outline,
                        label: 'Help / Contact admin',
                        tone: Tone.neutral,
                        onTap: () => showDialog<void>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            icon: const IconBadge(
                              icon: Icons.support_agent_rounded,
                              size: 48,
                            ),
                            title: const Text(
                              'Help / Contact admin',
                              textAlign: TextAlign.center,
                            ),
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
                  const SizedBox(height: 18),
                  SettingsGroup(
                    children: [
                      _Row(
                        icon: Icons.logout,
                        label: 'Sign out',
                        tone: Tone.danger,
                        danger: true,
                        showChevron: false,
                        onTap: () => _logout(context),
                      ),
                    ],
                  ),
                ],
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
    this.tone = Tone.primary,
    this.danger = false,
    this.showChevron = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Tone tone;
  final bool danger;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: IconBadge(icon: icon, tone: tone, size: 36),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: danger ? AppColors.danger : AppColors.text,
        ),
      ),
      trailing: showChevron
          ? const Icon(Icons.chevron_right_rounded, color: AppColors.textFaint)
          : null,
      onTap: onTap,
    );
  }
}
