import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/activity.dart';
import '../../services/admin_service.dart';
import 'admin_common.dart';

/// Admin: admin_logs (who did what, to which target, with details JSON)
class AdminLogsView extends StatefulWidget {
  const AdminLogsView({super.key});

  @override
  State<AdminLogsView> createState() => _AdminLogsViewState();
}

class _AdminLogsViewState extends State<AdminLogsView> {
  static const _targets = {
    'dormitory': 'หอพัก',
    'user': 'ผู้ใช้',
  };
  String? _target;
  late Future<List<AdminLog>> _future = _fetch();

  Future<List<AdminLog>> _fetch() => context.read<AdminService>().logs(targetType: _target);
  void _reload() => setState(() => _future = _fetch());

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      FilterChips(options: _targets, selected: _target, onSelected: (v) {
        _target = v;
        _reload();
      }),
      Expanded(
        child: AsyncList<AdminLog>(
          future: _future,
          onRetry: _reload,
          emptyText: 'ยังไม่มีบันทึก',
          emptyIcon: Icons.history,
          builder: (list) => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final l = list[i];
              final details = l.details?.entries.map((e) => '${e.key}: ${e.value}').join(' · ');
              return ListTile(
                leading: const Icon(Icons.history, color: AppColors.navy),
                title: Text('${adminActionLabels[l.action] ?? l.action} · ${_targets[l.targetType] ?? l.targetType} #${l.targetId ?? '-'}'),
                subtitle: Text([
                  '${l.adminName ?? '-'} · ${formatDateTime(l.createdAt)}',
                  if (details != null && details.isNotEmpty) details,
                ].join('\n')),
              );
            },
          ),
        ),
      ),
    ]);
  }
}
