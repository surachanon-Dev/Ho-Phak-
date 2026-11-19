import 'package:flutter/material.dart';

import '../controller/admin_settings_controller.dart';
import '../../../../core/app_services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../app/session.dart';
import '../../../auth/login/view/login_screen.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../widgets/ui/ui.dart';
import '../../widgets/admin_page.dart';

/// หน้า Settings ของแอดมิน: ข้อมูลบัญชี, เปลี่ยนรหัสผ่าน (ผ่าน /api/me/password), ออกจากระบบ
class AdminSettingsTab extends StatefulWidget {
  const AdminSettingsTab({super.key, required this.services});

  final AppServices services;

  @override
  State<AdminSettingsTab> createState() => _AdminSettingsTabState();
}

class _AdminSettingsTabState extends State<AdminSettingsTab> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late final AdminSettingsController _c;

  @override
  void initState() {
    super.initState();
    final services = widget.services;
    _c = AdminSettingsController(
      api: services.api,
      auth: services.auth,
      updatePassword: ({required currentPassword, required newPassword}) =>
          services.api.put('/api/me/password', {
            'current_password': currentPassword,
            'new_password': newPassword,
          }),
    );
    _c.addListener(() {
      if (mounted) setState(() {});
    });
    _c.loadAccount().then((ok) {
      if (!ok) _report();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _report() {
    if (mounted && _c.error != null) {
      showApiError(context, widget.services, _c.error!);
    }
  }

  Future<void> _changePassword() async {
    final ok = await _c.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
      confirmPassword: _confirmPasswordController.text,
    );
    if (!mounted) return;
    if (ok) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Password changed')));
    } else {
      _report();
    }
  }

  Future<void> _signOut() async {
    final ok = await _c.signOut();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => LoginScreen(services: widget.services),
        ),
        (route) => false,
      );
    } else {
      _report();
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = _c.account;
    final busy = _c.activity != AdminSettingsActivity.idle;
    final pad = adminPagePadding(context);
    final wide = isWideLayout(context);

    final accountCard = AppCard(
      padding: const EdgeInsets.all(20),
      child: _c.activity == AdminSettingsActivity.loading && account == null
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    InitialsAvatar(
                      name: account?.username ?? 'Admin',
                      size: 48,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account?.username ?? '-',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ToneBadge(
                            label: account?.role ?? '-',
                            tone: Tone.warning,
                            icon: Icons.shield_outlined,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(),
                InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: _c.supportPhone ?? '-',
                ),
                InfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Role',
                  value: account?.role ?? '-',
                ),
              ],
            ),
    );

    final passwordCard = AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle(
            'Change password',
            icon: Icons.lock_outline_rounded,
            subtitle: 'Use at least 8 characters',
          ),
          const SizedBox(height: 16),
          _PasswordField(
            controller: _currentPasswordController,
            label: 'Current password',
          ),
          const SizedBox(height: 12),
          _PasswordField(
            controller: _newPasswordController,
            label: 'New password',
          ),
          const SizedBox(height: 12),
          _PasswordField(
            controller: _confirmPasswordController,
            label: 'Confirm new password',
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: busy ? null : _changePassword,
            child: const Text('Update password'),
          ),
        ],
      ),
    );

    final signOut = AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const IconBadge(icon: Icons.logout_rounded, tone: Tone.danger),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Sign out of this device',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: busy ? null : _signOut,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: Color(0xFFF3B4B4)),
              minimumSize: const Size(0, 40),
            ),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    return AdminPage(
      title: 'Settings',
      subtitle: 'Your admin account and security',
      child: ListView(
        padding: EdgeInsets.fromLTRB(pad, 0, pad, pad),
        children: [
          ContentWidth(
            maxWidth: 1000,
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            accountCard,
                            const SizedBox(height: 16),
                            signOut,
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: passwordCard),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      accountCard,
                      const SizedBox(height: 16),
                      passwordCard,
                      const SizedBox(height: 16),
                      signOut,
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// ช่องรหัสผ่านพร้อมปุ่มแสดง/ซ่อน
class _PasswordField extends StatefulWidget {
  const _PasswordField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _hidden,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.key_outlined, size: 20),
        suffixIcon: IconButton(
          tooltip: _hidden ? 'Show' : 'Hide',
          onPressed: () => setState(() => _hidden = !_hidden),
          icon: Icon(
            _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 20,
          ),
        ),
      ),
    );
  }
}
