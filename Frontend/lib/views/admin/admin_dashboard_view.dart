import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../services/admin_service.dart';
import '../widgets/common.dart';

/// Admin overview: counts + pending work + recent admin_logs
class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key, required this.onOpen});
  final ValueChanged<int> onOpen; // index of the admin page to open

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  late Future<AdminStats> _future = context.read<AdminService>().stats();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snap.hasError) {
          return ErrorRetry(message: snap.error.toString(), onRetry: () => setState(() => _future = context.read<AdminService>().stats()));
        }
        final s = snap.data!;
        Widget todo(String label, int n, IconData icon, int page) => Card(
              child: ListTile(
                leading: Icon(icon, color: n > 0 ? AppColors.orange : AppColors.muted),
                title: Text(label),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (n > 0) Badge(label: Text('$n'), backgroundColor: AppColors.orange) else const Text('0'),
                  const Icon(Icons.chevron_right),
                ]),
                onTap: () => widget.onOpen(page),
              ),
            );

        return RefreshIndicator(
          onRefresh: () async {
            final f = context.read<AdminService>().stats();
            setState(() => _future = f);
            await f;
          },
          child: ListView(padding: const EdgeInsets.all(16), children: [
            GridView.extent(
              maxCrossAxisExtent: 280,
              childAspectRatio: 1.6,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StatCard(label: 'นักศึกษา', value: '${s.usersByRole['student'] ?? 0}', icon: Icons.school_outlined),
                StatCard(label: 'เจ้าของหอพัก', value: '${s.usersByRole['owner'] ?? 0}', icon: Icons.person_pin_outlined, color: AppColors.navy),
                StatCard(label: 'หอพักเผยแพร่', value: '${s.dormsByStatus['published'] ?? 0}', icon: Icons.apartment, color: AppColors.success),
                StatCard(label: 'ผู้ใช้ถูกระงับ', value: '${s.suspendedUsers}', icon: Icons.block, color: AppColors.danger),
              ],
            ),
            const SectionTitle('งานที่รอดำเนินการ'),
            todo('หอพักใหม่รออนุมัติ (ตรวจรูป + เอกสาร)', s.dormsByStatus['pending'] ?? 0, Icons.apartment_outlined, 1),
            Card(
              child: ListTile(
                leading: const Icon(Icons.rate_review_outlined, color: AppColors.teal),
                title: const Text('รีวิวทั้งหมด'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text('${s.totalReviews}'), const Icon(Icons.chevron_right)]),
                onTap: () => widget.onOpen(3),
              ),
            ),
            const SectionTitle('หอพักตามสถานะ'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final st in dormStatusLabels.keys) Chip(label: Text('${dormStatusLabels[st]}: ${s.dormsByStatus[st] ?? 0}')),
            ]),
            SectionTitle('บันทึกล่าสุด', trailing: TextButton(onPressed: () => widget.onOpen(4), child: const Text('ดูทั้งหมด'))),
            if (s.recentLogs.isEmpty) const Text('ยังไม่มีบันทึก', style: TextStyle(color: AppColors.muted)),
            for (final l in s.recentLogs)
              ListTile(
                dense: true,
                leading: const Icon(Icons.history, size: 20),
                title: Text('${adminActionLabels[l.action] ?? l.action} · ${l.targetType} #${l.targetId ?? '-'}'),
                subtitle: Text('${l.adminName ?? '-'} · ${formatDateTime(l.createdAt)}'),
              ),
          ]),
        );
      },
    );
  }
}
