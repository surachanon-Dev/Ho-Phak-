import 'package:flutter/material.dart';

import 'admin_profile_controller.dart';
import '../../../core/app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_handling.dart';
import '../../auth/screens/login_screen.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('โปรไฟล์')),
      body: _c.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.admin_panel_settings_outlined),
                    ),
                    title: Text(u?.username ?? 'แอดมิน'),
                    subtitle: Text(
                      'บทบาท: ${u?.role ?? '-'} · ID ${u?.id ?? '-'}',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.refresh),
                    title: const Text('โหลดข้อมูลบัญชีใหม่'),
                    onTap: _c.load,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.danger),
                    title: const Text(
                      'ออกจากระบบ',
                      style: TextStyle(color: AppColors.danger),
                    ),
                    onTap: _logout,
                  ),
                ),
              ],
            ),
    );
  }
}
