import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/owner_controller.dart';
import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/dormitory.dart';
import '../widgets/common.dart';
import '../widgets/dorm_card.dart';
import 'dorm_form_view.dart';
import 'owner_shell.dart';

/// Owner: only MY dorms, filter by status, actions per status
class OwnerDormsView extends StatefulWidget {
  const OwnerDormsView({super.key});

  @override
  State<OwnerDormsView> createState() => _OwnerDormsViewState();
}

class _OwnerDormsViewState extends State<OwnerDormsView> {
  String? _status;

  Future<void> _edit(Dormitory d) async {
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => DormFormView(dormId: d.id)));
    if (saved == true && mounted) refreshAll(context);
  }

  Future<void> _action(String action, Dormitory d) async {
    final service = context.read<OwnerController>().service;
    try {
      switch (action) {
        case 'edit':
          return _edit(d);
        case 'hide':
          await service.setHidden(d.id, true);
          if (mounted) showSnack(context, 'ซ่อนหอพักแล้ว – นักศึกษาจะมองไม่เห็น');
        case 'unhide':
          await service.setHidden(d.id, false);
          if (mounted) showSnack(context, 'แสดงหอพักอีกครั้งแล้ว');
        case 'delete':
          final ok = await confirmDialog(context, 'ลบหอพัก', 'ต้องการลบ "${d.name}" ใช่ไหม?\nรูป รีวิว และรายการโปรดของหอนี้จะถูกลบด้วย',
              confirm: 'ลบ', danger: true);
          if (!ok) return;
          await service.delete(d.id);
          if (mounted) showSnack(context, 'ลบหอพักแล้ว');
      }
      if (mounted) refreshAll(context);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  String? _reasonOf(Dormitory d) => switch (d.status) {
        'rejected' => d.rejectionReason,
        'suspended' => d.statusReason,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.watch<OwnerController>();
    final list = c.dorms.where((d) => _status == null || d.status == _status).toList();

    return Column(children: [
      SizedBox(
        height: 52,
        child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(label: Text('ทั้งหมด (${c.dorms.length})'), selected: _status == null, onSelected: (_) => setState(() => _status = null)),
          ),
          for (final s in dormStatusLabels.keys)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text('${dormStatusLabels[s]} (${c.dorms.where((d) => d.status == s).length})'),
                selected: _status == s,
                onSelected: (_) => setState(() => _status = s),
              ),
            ),
        ]),
      ),
      Expanded(
        child: c.loading && c.dorms.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : c.error != null && c.dorms.isEmpty
                ? ErrorRetry(message: c.error!, onRetry: () => refreshAll(context))
                : list.isEmpty
                    ? const EmptyState(icon: Icons.apartment_outlined, message: 'ยังไม่มีหอพักในสถานะนี้\nกด "เพิ่มหอพัก" เพื่อลงประกาศ')
                    : RefreshIndicator(
                        onRefresh: () async => refreshAll(context),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final d = list[i];
                            final reason = _reasonOf(d);
                            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                              DormCard(
                                dorm: d,
                                showStatus: true,
                                onTap: d.status == 'suspended' ? null : () => _edit(d),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (a) => _action(a, d),
                                  itemBuilder: (_) => [
                                    PopupMenuItem(value: 'edit', enabled: d.status != 'suspended', child: const Text('แก้ไข')),
                                    if (d.status == 'published') const PopupMenuItem(value: 'hide', child: Text('ซ่อนจากนักศึกษา')),
                                    if (d.status == 'hidden') const PopupMenuItem(value: 'unhide', child: Text('แสดงอีกครั้ง')),
                                    const PopupMenuItem(value: 'delete', child: Text('ลบ', style: TextStyle(color: AppColors.danger))),
                                  ],
                                ),
                              ),
                              if (reason != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4, left: 8),
                                  child: Text('เหตุผล: $reason', style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                                ),
                            ]);
                          },
                        ),
                      ),
      ),
    ]);
  }
}
