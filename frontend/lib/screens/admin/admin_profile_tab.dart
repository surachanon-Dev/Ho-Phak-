import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../services/app_services.dart';
import '../../ui/app_theme.dart';
import '../../ui/error_handling.dart';
import '../login_screen.dart';

/// โปรไฟล์แอดมิน: แสดงบัญชีที่ login อยู่ และออกจากระบบ
class AdminProfileTab extends StatefulWidget {
  const AdminProfileTab({super.key, required this.services});

  final AppServices services;

  @override
  State<AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<AdminProfileTab> {
  CurrentUser? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final u = await widget.services.auth.currentUser();
      if (mounted) setState(() => _user = u);
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
    await widget.services.auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen(services: widget.services)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = _user;
    return Scaffold(
      appBar: AppBar(title: const Text('โปรไฟล์')),
      body: _loading
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
                    onTap: _load,
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
