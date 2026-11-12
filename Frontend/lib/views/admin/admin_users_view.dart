import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/user.dart';
import '../../services/admin_service.dart';
import '../widgets/common.dart';
import 'admin_common.dart';

/// Admin: users – filter by role / status, suspend (reason) / activate (admins cannot be managed)
class AdminUsersView extends StatefulWidget {
  const AdminUsersView({super.key});

  @override
  State<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<AdminUsersView> {
  String? _role;
  String? _status;
  String _q = '';
  late Future<List<AppUser>> _future = _fetch();

  Future<List<AppUser>> _fetch() => context.read<AdminService>().users(role: _role, status: _status, q: _q);
  void _reload() => setState(() => _future = _fetch());

  @override
  Widget build(BuildContext context) {
    final s = context.read<AdminService>();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: TextField(
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ค้นหาชื่อผู้ใช้ หรือ เบอร์โทร'),
          onSubmitted: (v) {
            _q = v;
            _reload();
          },
        ),
      ),
      FilterChips(options: roleLabels, selected: _role, allLabel: 'ทุกบทบาท', onSelected: (v) {
        _role = v;
        _reload();
      }),
      FilterChips(options: userStatusLabels, selected: _status, allLabel: 'ทุกสถานะ', onSelected: (v) {
        _status = v;
        _reload();
      }),
      Expanded(
        child: AsyncList<AppUser>(
          future: _future,
          onRetry: _reload,
          emptyText: 'ไม่พบผู้ใช้',
          emptyIcon: Icons.people_outline,
          builder: (list) => ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final u = list[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: u.isSuspended ? AppColors.danger.withValues(alpha: 0.15) : AppColors.teal.withValues(alpha: 0.15),
                    child: Icon(switch (u.role) { 'owner' => Icons.person_pin, 'admin' => Icons.admin_panel_settings, _ => Icons.school }),
                  ),
                  title: Text(u.displayName, overflow: TextOverflow.ellipsis),
                  subtitle: Text([
                    '${roleLabels[u.role]} · ${u.phone}',
                    if (u.isSuspended) 'ระงับ: ${u.suspensionReason ?? '-'} (${formatDate(u.suspendedAt)})',
                  ].join('\n')),
                  isThreeLine: u.isSuspended,
                  trailing: u.isAdmin
                      ? StatusChip(u.status, label: userStatusLabels[u.status])
                      : u.isSuspended
                          ? TextButton(
                              onPressed: () async {
                                if (await runAdmin(context, () => s.activateUser(u.id), 'เปิดใช้งานบัญชีแล้ว')) _reload();
                              },
                              child: const Text('เปิดใช้งาน'),
                            )
                          : TextButton(
                              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                              onPressed: () async {
                                if (await runWithReason(context, 'ระงับผู้ใช้ ${u.displayName}', (r) => s.suspendUser(u.id, r), 'ระงับผู้ใช้แล้ว')) {
                                  _reload();
                                }
                              },
                              child: const Text('ระงับ'),
                            ),
                ),
              );
            },
          ),
        ),
      ),
    ]);
  }
}
