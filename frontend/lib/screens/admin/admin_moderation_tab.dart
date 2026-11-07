import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../services/app_services.dart';
import '../../ui/app_theme.dart';
import '../../ui/error_handling.dart';
import 'admin_reviews_tab.dart';

/// จัดการการระงับ: เลือกหอพักหรือผู้ใช้จากรายการ แล้วระงับหรือคืนสถานะ
class AdminModerationTab extends StatefulWidget {
  const AdminModerationTab({super.key, required this.services});

  final AppServices services;

  @override
  State<AdminModerationTab> createState() => _AdminModerationTabState();
}

class _AdminModerationTabState extends State<AdminModerationTab> {
  late final AdminService _admin = AdminService(widget.services.api);
  List<Map<String, dynamic>> _dorms = [];
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _admin.allDormitories(),
        _admin.allUsers(),
      ]);
      if (!mounted) return;
      setState(() {
        _dorms = results[0];
        // แสดงเฉพาะบัญชีที่ไม่ใช่แอดมิน เพราะระงับแอดมินไม่ได้
        _users = results[1].where((u) => u['role'] != 'admin').toList();
      });
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(done)));
      }
      await _load();
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _suspendDorm(Map<String, dynamic> d) async {
    final reason = await askReason(context, 'เหตุผลการระงับหอพัก');
    if (reason == null) return;
    final id = d['id'] as int;
    await _run(() => _admin.suspendDormitory(id, reason), 'ระงับหอพักแล้ว');
  }

  Future<void> _suspendUser(Map<String, dynamic> u) async {
    final reason = await askReason(context, 'เหตุผลการระงับบัญชี');
    if (reason == null) return;
    final id = u['id'] as int;
    await _run(() => _admin.suspendUser(id, reason), 'ระงับบัญชีแล้ว');
  }

  Widget _row({
    required String title,
    required String subtitle,
    required String statusText,
    required bool suspended,
    required VoidCallback onAction,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                color: suspended ? AppColors.danger : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            if (suspended)
              OutlinedButton(onPressed: onAction, child: const Text('คืนสถานะ'))
            else
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  minimumSize: const Size(0, 36),
                ),
                onPressed: onAction,
                child: const Text('ระงับ'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ระงับและคืนสถานะ'),
        actions: [
          IconButton(
            tooltip: 'รีเฟรช',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: _loading && _dorms.isEmpty && _users.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'หอพัก (${_dorms.length})',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    if (_dorms.isEmpty)
                      const Text(
                        'ไม่มีหอพัก',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    for (final d in _dorms)
                      _row(
                        title: '${d['name']}',
                        subtitle:
                            '${d['zone']} · เจ้าของ ${d['owner_username'] ?? '-'}',
                        statusText: '${d['status']}',
                        suspended: d['status'] == 'suspended',
                        onAction: () => d['status'] == 'suspended'
                            ? _run(
                                () => _admin.restoreDormitory(d['id'] as int),
                                'คืนสถานะหอพักแล้ว',
                              )
                            : _suspendDorm(d),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'ผู้ใช้ (${_users.length})',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    if (_users.isEmpty)
                      const Text(
                        'ไม่มีผู้ใช้',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    for (final u in _users)
                      _row(
                        title: '${u['username'] ?? '-'}',
                        subtitle: '${u['phone'] ?? '-'} · ${u['role']}',
                        statusText: '${u['status']}',
                        suspended: u['status'] == 'suspended',
                        onAction: () => u['status'] == 'suspended'
                            ? _run(
                                () => _admin.restoreUser(u['id'] as int),
                                'คืนสถานะบัญชีแล้ว',
                              )
                            : _suspendUser(u),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
