import 'package:flutter/material.dart';

import '../../../../app/home_router.dart';
import '../../../../app/session.dart';
import '../../../../core/app_services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../model/user.dart';
import '../../../../widgets/ui/ui.dart';
import '../../../auth/welcome/view/welcome_screen.dart';
import '../../../notifications/view/notifications_screen.dart';
import '../../../owner/profile/controller/owner_profile_controller.dart';
import '../../../owner/change_password/view/change_password_screen.dart';
import '../../../owner/profile/view/edit_profile_screen.dart';
import '../../../owner/notification_settings/view/notification_settings_screen.dart';
import '../../../owner/widgets/owner_ui.dart' show SettingsGroup;
import '../../widgets/student_ui.dart';
import '../../my_reviews/view/my_reviews_screen.dart';

/// โปรไฟล์นักศึกษา: แก้ไขโปรไฟล์, เปลี่ยนรหัสผ่าน, ตั้งค่าการแจ้งเตือน,
/// รีวิวของฉัน, สมัครเป็นเจ้าของหอ, ติดต่อแอดมิน และออกจากระบบ
/// (หน้าแก้โปรไฟล์/รหัสผ่าน/ตั้งค่าแจ้งเตือนใช้ร่วมกับ owner เพราะเรียก /api/me เหมือนกัน)
class StudentProfileScreen extends StatefulWidget {
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

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  late final OwnerProfileController _c;
  bool _busy = false;
  String? _adminPhone;

  AppServices get services => widget.services;

  @override
  void initState() {
    super.initState();
    _c = OwnerProfileController(
      account: services.account,
      auth: services.auth,
      fallbackName: widget.user.username,
    );
    _c.addListener(_onChanged);
    _c.load();
    _loadAdminPhone();
  }

  Future<void> _loadAdminPhone() async {
    final phone = await services.auth.supportContactPhone();
    if (mounted) setState(() => _adminPhone = phone);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _c.removeListener(_onChanged);
    _c.dispose();
    super.dispose();
  }

  Future<void> _push(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  Future<void> _editProfile() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            EditProfileScreen(services: services, profile: _c.profile),
      ),
    );
    if (saved == true) _c.load();
  }

  Future<void> _becomeOwner() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const IconBadge(icon: Icons.home_work_outlined, size: 48),
        title: const Text('Become a dorm owner?'),
        content: const Text(
          'Your account will switch to an owner account. You will need to '
          'send an identity document, and an admin must approve it before you '
          'can list dorms. You will no longer use the student pages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final user = await services.auth.becomeOwner();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => homeFor(services, user)),
        (route) => false,
      );
    } catch (e) {
      if (mounted) showApiError(context, services, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _contactAdmin() => showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const IconBadge(icon: Icons.support_agent_rounded, size: 48),
      title: const Text('Contact admin', textAlign: TextAlign.center),
      content: Text(
        _adminPhone != null
            ? 'For help with your account or dorm listings, please call the admin at $_adminPhone.'
            : 'Admin contact details have not been set yet.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _c.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => WelcomeScreen(services: services)),
      (route) => false,
    );
  }

  Widget _item(
    IconData icon,
    Tone tone,
    String title,
    VoidCallback? onTap, {
    String? subtitle,
    Color? color,
  }) => ListTile(
    leading: IconBadge(icon: icon, tone: tone, size: 36),
    title: Text(title, style: color == null ? null : TextStyle(color: color)),
    subtitle: subtitle == null ? null : Text(subtitle),
    trailing: color == null ? const Icon(Icons.chevron_right_rounded) : null,
    onTap: onTap,
  );

  @override
  Widget build(BuildContext context) {
    final profile = _c.profile;
    final name = profile.fullName.isNotEmpty
        ? profile.fullName
        : (widget.user.username ?? 'Student #${widget.user.id}');
    return Scaffold(
      appBar: AppBar(
        // อยู่ในแท็บของ StudentShell (มี actions) ไม่ต้องมีปุ่มย้อนกลับ
        automaticallyImplyLeading: widget.actions == null,
        title: const Text('Profile'),
        actions: widget.actions,
      ),
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
                      ProfileAvatar(photoBase64: profile.photoBase64, size: 60),
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
                            if (profile.phone.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                profile.phone,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            const ToneBadge(
                              label: 'Student',
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
                  title: 'Account',
                  children: [
                    _item(
                      Icons.person_outline_rounded,
                      Tone.primary,
                      'Edit profile',
                      _editProfile,
                    ),
                    _item(
                      Icons.lock_outline_rounded,
                      Tone.violet,
                      'Change password',
                      () => _push(ChangePasswordScreen(services: services)),
                    ),
                    _item(
                      Icons.tune_rounded,
                      Tone.info,
                      'Notification settings',
                      () => _push(
                        NotificationSettingsScreen(
                          services: services,
                          forStudent: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SettingsGroup(
                  title: 'Activity',
                  children: [
                    _item(
                      Icons.rate_review_outlined,
                      Tone.warning,
                      'My reviews',
                      () => _push(
                        MyReviewsScreen(
                          services: services,
                          myUserId: widget.user.id,
                        ),
                      ),
                    ),
                    _item(
                      Icons.notifications_none_rounded,
                      Tone.info,
                      'Notifications',
                      () => _push(NotificationsScreen(services: services)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SettingsGroup(
                  title: 'More',
                  children: [
                    _item(
                      Icons.home_work_outlined,
                      Tone.success,
                      'Become a dorm owner',
                      _busy ? null : _becomeOwner,
                      subtitle: 'List your own dorm on Ho-Phak',
                    ),
                    _item(
                      Icons.support_agent_rounded,
                      Tone.neutral,
                      'Contact admin',
                      _contactAdmin,
                      subtitle: _adminPhone ?? 'Get help from Ho-Phak admin',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SettingsGroup(
                  children: [
                    _item(
                      Icons.logout_rounded,
                      Tone.danger,
                      'Log out',
                      _logout,
                      color: AppColors.danger,
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
