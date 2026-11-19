import 'package:flutter/material.dart';

import '../controller/admin_profile_controller.dart';
import '../../../../core/app_services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../app/session.dart';
import '../../../auth/login/view/login_screen.dart';
import '../../../../widgets/ui/ui.dart';
import '../../widgets/admin_page.dart';

/// โปรไฟล์แอดมิน: แสดงบัญชีที่ login อยู่ และออกจากระบบ
class AdminProfileTab extends StatefulWidget {
  const AdminProfileTab({super.key, required this.services});

  final AppServices services;

  @override
  State<AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<AdminProfileTab> {
  late final AdminProfileController _c;

  @override
  void initState() {
    super.initState();
    _c = AdminProfileController(widget.services.auth);
    _c.addListener(() {
      if (mounted) setState(() {});
    });
    _c.load().then((ok) {
      if (!ok && mounted && _c.error != null) {
        showApiError(context, widget.services, _c.error!);
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const IconBadge(
          icon: Icons.logout_rounded,
          tone: Tone.danger,
          size: 44,
        ),
        title: const Text('Log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
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
      MaterialPageRoute(builder: (_) => LoginScreen(services: widget.services)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = _c.user;
    final pad = adminPagePadding(context);
    return AdminPage(
      title: 'Profile',
      subtitle: 'The admin account you are signed in with',
      child: _c.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(pad, 0, pad, pad),
              children: [
                ContentWidth(
                  maxWidth: 640,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0x33FFFFFF),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.lg,
                                ),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings_outlined,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    u?.username ?? 'Admin',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Role: ${u?.role ?? '-'} · ID ${u?.id ?? '-'}',
                                    style: const TextStyle(
                                      color: Color(0xE6FFFFFF),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: const IconBadge(
                                icon: Icons.refresh,
                                size: 36,
                              ),
                              title: const Text('Reload account'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: _c.load,
                            ),
                            const Divider(indent: 16, endIndent: 16),
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: const IconBadge(
                                icon: Icons.logout_rounded,
                                tone: Tone.danger,
                                size: 36,
                              ),
                              title: const Text(
                                'Log out',
                                style: TextStyle(color: AppColors.danger),
                              ),
                              onTap: _logout,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
