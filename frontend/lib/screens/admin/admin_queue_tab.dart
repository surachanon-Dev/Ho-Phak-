import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../services/app_services.dart';
import '../../ui/app_theme.dart';
import '../../ui/error_handling.dart';
import '../login_screen.dart';

/// หน้าแอดมิน: คิวรอตรวจ (หอใหม่, ฉบับแก้ไข, การยืนยันเจ้าของ)
/// หมายเหตุ: ดีไซน์ของแอดมินยังไม่มีใน Figma จึงทำแบบรายการพื้นฐานก่อน
class AdminQueueTab extends StatefulWidget {
  const AdminQueueTab({super.key, required this.services});

  final AppServices services;

  @override
  State<AdminQueueTab> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminQueueTab> {
  late final AdminService _admin = AdminService(widget.services.api);
  AdminQueue? _queue;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final q = await _admin.queue();
      if (mounted) setState(() => _queue = q);
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(Future<void> Function() action) async {
    try {
      await action();
      await _load();
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    }
  }

  Future<void> _reject(Future<void> Function(String reason) action) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('เหตุผลที่ปฏิเสธ'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'ระบุเหตุผล (จำเป็น)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('ปฏิเสธ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || reason.isEmpty) return;
    await _approve(() => action(reason));
  }

  Future<void> _logout() async {
    await widget.services.auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen(services: widget.services)),
      (route) => false,
    );
  }

  Widget _section(String title, List<Widget> rows) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          const Text(
            'ไม่มีรายการรอตรวจ',
            style: TextStyle(color: AppColors.textMuted),
          )
        else
          ...rows,
      ],
    ),
  );

  Widget _item(String title, String subtitle, List<Widget> actions) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final q = _queue;
    return Scaffold(
      appBar: AppBar(
        title: const Text('คิวตรวจสอบ'),
        actions: [
          IconButton(
            tooltip: 'รีเฟรช',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
          IconButton(
            tooltip: 'ออกจากระบบ',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading && q == null
          ? const Center(child: CircularProgressIndicator())
          : q == null
          ? const Center(child: Text('โหลดคิวไม่ได้'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _section('หอพักใหม่ (${q.newDormitories.length})', [
                    for (final d in q.newDormitories)
                      _item(
                        '${d['name']}',
                        '${d['zone']} · เจ้าของ ${d['owner_username'] ?? '-'}',
                        [
                          TextButton(
                            onPressed: () => _reject(
                              (r) => _admin.rejectDormitory(d['id'] as int, r),
                            ),
                            child: const Text('ปฏิเสธ'),
                          ),
                          FilledButton(
                            onPressed: () => _approve(
                              () => _admin.approveDormitory(d['id'] as int),
                            ),
                            child: const Text('อนุมัติ'),
                          ),
                        ],
                      ),
                  ]),
                  _section('ฉบับแก้ไข (${q.revisions.length})', [
                    for (final r in q.revisions)
                      _item(
                        '${r['dormitory_name']}',
                        'ส่งเมื่อ ${r['submitted_at']}',
                        [
                          TextButton(
                            onPressed: () => _reject(
                              (reason) => _admin.rejectDormitory(
                                r['dormitory_id'] as int,
                                reason,
                              ),
                            ),
                            child: const Text('ปฏิเสธ'),
                          ),
                          FilledButton(
                            onPressed: () => _approve(
                              () => _admin.approveDormitory(
                                r['dormitory_id'] as int,
                              ),
                            ),
                            child: const Text('อนุมัติ'),
                          ),
                        ],
                      ),
                  ]),
                  _section('การยืนยันเจ้าของ (${q.verifications.length})', [
                    for (final v in q.verifications)
                      _item(
                        'เบอร์ ${v['owner_phone']}',
                        '${v['document_url']}',
                        [
                          TextButton(
                            onPressed: () => _reject(
                              (r) =>
                                  _admin.rejectVerification(v['id'] as int, r),
                            ),
                            child: const Text('ปฏิเสธ'),
                          ),
                          FilledButton(
                            onPressed: () => _approve(
                              () => _admin.approveVerification(v['id'] as int),
                            ),
                            child: const Text('อนุมัติ'),
                          ),
                        ],
                      ),
                  ]),
                ],
              ),
            ),
    );
  }
}
