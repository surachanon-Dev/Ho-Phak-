import 'package:flutter/material.dart';

import 'package:hopak_frontend/features/admin/settings/settings_controller.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/core/theme/app_theme.dart';
import 'package:hopak_frontend/core/utils/error_handling.dart';
import 'package:hopak_frontend/features/auth/login/login_screen.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เปลี่ยนรหัสผ่านแล้ว')),
      );
    } else {
      _report();
    }
  }

  Future<void> _signOut() async {
    final ok = await _c.signOut();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen(services: widget.services)),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _c.activity == AdminSettingsActivity.loading && account == null
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account?.username ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Phone: ${_c.supportPhone ?? '-'}',
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                        Text(
                          'Role: ${account?.role ?? '-'}',
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Change password',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _currentPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Current password'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'New password'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm new password'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: busy ? null : _changePassword,
                    child: const Text('Update password'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: busy ? null : _signOut,
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
