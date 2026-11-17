import 'package:flutter/material.dart';

import '../../controllers/admin_dorms_controller.dart';
import '../../services/admin_service.dart';
import '../../services/app_services.dart';
import '../../ui/error_handling.dart';

/// หน้า Dorms ของแอดมิน (เมนู Dorms)
/// - Awaiting review: หอใหม่และฉบับแก้ไขที่รอตรวจ อนุมัติ/ปฏิเสธ
/// - All dorms: หอทั้งหมด กรองตามสถานะ ระงับ/ยกเลิกการระงับ
class AdminDormsTab extends StatefulWidget {
  const AdminDormsTab({super.key, required this.services});

  final AppServices services;

  @override
  State<AdminDormsTab> createState() => _AdminDormsTabState();
}

class _AdminDormsTabState extends State<AdminDormsTab>
    with SingleTickerProviderStateMixin {
  late final AdminDormsController _c;
  late final TabController _tabs;

  static const _statusFilters = <String?, String>{
    null: 'All statuses',
    'published': 'Published',
    'hidden': 'Hidden',
    'suspended': 'Suspended',
    'rejected': 'Rejected',
  };

  @override
  void initState() {
    super.initState();
    _c = AdminDormsController(AdminService(widget.services.api));
    _c.addListener(() {
      if (mounted) setState(() {});
    });
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (mounted) setState(() {});
    });
    _c.refreshAll();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _c.dispose();
    super.dispose();
  }

  void _report(bool ok) {
    if (!mounted) return;
    if (!ok && _c.error != null) {
      showApiError(context, widget.services, _c.error!);
    }
  }

  /// ขอเหตุผลจากแอดมินก่อนปฏิเสธ/ระงับ คืนค่าว่างถ้ากดยกเลิก
  Future<String?> _askReason(String title, String hint) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: AdminDormsController.maxReasonLength,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    controller.dispose();
    return reason;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dorms'),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: 'Awaiting review (${_c.awaitingCount})'),
            Tab(text: 'All dorms'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _c.loading ? null : () => _c.refreshAll(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_awaitingList(), _allList()],
      ),
    );
  }

  Widget _awaitingList() {
    final rows = [
      for (final d in _c.newDormitories) (d, 'New dorm'),
      for (final r in _c.revisions) (r, 'Edit request'),
    ];
    if (_c.loading && rows.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (rows.isEmpty) {
      return const Center(child: Text('Nothing waiting for review'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final (row, kind) = rows[i];
        final dormId = (row['dormitory_id'] ?? row['id']) as num;
        final name = (row['name'] ?? row['dormitory_name'] ?? '-').toString();
        final zone = row['zone']?.toString();
        return Card(
          child: ListTile(
            title: Text(name),
            subtitle: Text(
              [kind, if (zone != null) zone, if (row['owner_username'] != null) 'by ${row['owner_username']}']
                  .join(' · '),
            ),
            trailing: Wrap(
              spacing: 4,
              children: [
                TextButton(
                  onPressed: _c.busy ? null : () => _reject(dormId.toInt()),
                  child: const Text('Reject'),
                ),
                FilledButton(
                  onPressed: _c.busy
                      ? null
                      : () async => _report(await _c.approve(dormId.toInt())),
                  child: const Text('Approve'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _reject(int dormId) async {
    final reason = await _askReason('Reject this dorm?', 'Reason (required)');
    if (reason == null) return;
    _report(await _c.reject(dormId, reason));
  }

  Widget _allList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: DropdownButtonFormField<String?>(
            initialValue: _c.statusFilter,
            decoration: const InputDecoration(labelText: 'Status', isDense: true),
            items: [
              for (final e in _statusFilters.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (v) => _c.loadAll(status: v),
          ),
        ),
        Expanded(
          child: _c.loading && _c.allDormitories.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _c.allDormitories.isEmpty
              ? const Center(child: Text('No dorms'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _c.allDormitories.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final d = _c.allDormitories[i];
                    final id = (d['id'] as num).toInt();
                    final status = (d['status'] ?? '').toString();
                    return Card(
                      child: ListTile(
                        title: Text((d['name'] ?? '-').toString()),
                        subtitle: Text(
                          '${d['zone'] ?? '-'} · $status · '
                          'owner ${d['owner_username'] ?? d['owner_id'] ?? '-'}',
                        ),
                        trailing: status == 'suspended'
                            ? OutlinedButton(
                                onPressed: _c.busy
                                    ? null
                                    : () async => _report(await _c.restore(id)),
                                child: const Text('Restore'),
                              )
                            : OutlinedButton(
                                onPressed: _c.busy ? null : () => _suspend(id),
                                child: const Text('Suspend'),
                              ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _suspend(int dormId) async {
    final reason = await _askReason('Suspend this dorm?', 'Reason (required)');
    if (reason == null) return;
    _report(await _c.suspend(dormId, reason));
  }
}
