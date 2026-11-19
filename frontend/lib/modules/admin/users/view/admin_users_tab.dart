import 'package:flutter/material.dart';

import '../../../../core/app_services.dart';
import '../../../../app/session.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../widgets/ui/ui.dart';
import '../../widgets/admin_page.dart';
import '../../../../services/admin_service.dart';
import '../../user_detail/controller/admin_user_detail_controller.dart';
import '../../user_detail/view/admin_user_detail_screen.dart';
import '../controller/admin_users_controller.dart';
import 'widgets/user_list_widgets.dart';

//// หน้า Users: รายการผู้ใช้ ค้นหา/กรอง และเปิดรายละเอียด
class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key, required this.services});

  final AppServices services;

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  String _searchQuery = '';
  String _roleFilter = 'All roles';
  String _statusFilter = 'All statuses';
  String? _selectedUserId;

  late final AdminUsersController _uc;

  List<_UserRowData> get _users => _uc.users.map(_UserRowData.fromRow).toList();

  /// กลับจากหน้ารายละเอียดผู้ใช้ และโหลดรายการใหม่ (สถานะอาจเปลี่ยนจากการระงับ)
  void _backToUsers() {
    setState(() => _selectedUserId = null);
    _uc.load();
  }

  @override
  void initState() {
    super.initState();
    _uc = AdminUsersController(AdminService(widget.services.api));
    _uc.addListener(_onChanged);
    _uc.load().then((ok) {
      if (!ok && mounted && _uc.error != null) {
        showApiError(context, widget.services, _uc.error!);
      }
    });
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _uc.removeListener(_onChanged);
    _uc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedUserId != null) {
      return AdminUserDetailScreen(
        services: widget.services,
        userId: int.parse(_selectedUserId!),
        onBack: _backToUsers,
      );
    }
    return _buildUsersListView();
  }

  Widget _buildUsersListView() {
    final filtered = _users.where((u) {
      if (_roleFilter != 'All roles' && u.role != _roleFilter) {
        return false;
      }
      if (_statusFilter != 'All statuses' && u.status != _statusFilter) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return u.name.toLowerCase().contains(q) ||
            u.phone.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    final wide = isWideLayout(context);
    final search = SearchField(
      hint: 'Search name or phone...',
      onChanged: (v) => setState(() => _searchQuery = v),
    );
    final filters = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        FilterDropdown(
          icon: Icons.badge_outlined,
          value: _roleFilter,
          items: const ['All roles', 'Owner', 'Student', 'Admin'],
          onChanged: (v) {
            if (v != null) setState(() => _roleFilter = v);
          },
        ),
        FilterDropdown(
          icon: Icons.toggle_on_outlined,
          value: _statusFilter,
          items: const ['All statuses', 'Active', 'Suspended'],
          onChanged: (v) {
            if (v != null) setState(() => _statusFilter = v);
          },
        ),
      ],
    );

    return AdminPage(
      title: 'Users',
      subtitle: '${filtered.length} users · manage owners and students',
      actions: [
        HeaderIconButton(
          tooltip: 'Refresh',
          icon: Icons.refresh,
          onPressed: _uc.loading ? null : () => _uc.load(),
        ),
      ],
      toolbar: wide
          ? Row(
              children: [
                SizedBox(width: 300, child: search),
                const SizedBox(width: 12),
                Expanded(child: filters),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [search, const SizedBox(height: 10), filters],
            ),
      child: _uc.loading && _users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : filtered.isEmpty
          ? const EmptyState(
              icon: Icons.person_search_outlined,
              tone: Tone.neutral,
              title: 'No users',
              message: 'Try another search or filter.',
            )
          : AdminListView(
              itemCount: filtered.length + 1,
              separator: 8,
              itemBuilder: (context, i) {
                if (i == filtered.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Showing ${filtered.length} of ${_users.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  );
                }
                final u = filtered[i];
                return _UserCard(
                  user: u,
                  wide: wide,
                  onView: u.role == 'Admin'
                      ? null
                      : () => setState(() => _selectedUserId = u.id),
                );
              },
            ),
    );
  }
}

/// ผู้ใช้ 1 คน: จอกว้างเรียงเป็นแถวแบบตาราง จอแคบเป็นการ์ด
class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.wide, this.onView});

  final _UserRowData user;
  final bool wide;
  final VoidCallback? onView;

  @override
  Widget build(BuildContext context) {
    final u = user;
    final identity = Row(
      children: [
        InitialsAvatar(
          name: u.name,
          size: 40,
          tone: switch (u.role) {
            'Owner' => Tone.primary,
            'Admin' => Tone.warning,
            _ => Tone.info,
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                u.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                u.phone,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final joined = Text(
      'Joined ${u.joined}',
      style: const TextStyle(fontSize: 12.5, color: AppColors.textBody),
    );

    final view = onView == null
        ? const SizedBox(width: 36)
        : IconButton(
            tooltip: 'View',
            onPressed: onView,
            icon: const Icon(Icons.chevron_right_rounded),
          );

    if (wide) {
      return AppCard(
        onTap: onView,
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Expanded(flex: 4, child: identity),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: RolePill(role: u.role),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: UserStatusPill(status: u.status),
              ),
            ),
            Expanded(flex: 2, child: joined),
            view,
          ],
        ),
      );
    }

    return AppCard(
      onTap: onView,
      padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                identity,
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    RolePill(role: u.role),
                    UserStatusPill(status: u.status),
                    joined,
                  ],
                ),
              ],
            ),
          ),
          view,
        ],
      ),
    );
  }
}

class _UserRowData {
  /// แปลงแถวจาก GET /api/admin/users (ไม่มีรหัสผ่าน)
  factory _UserRowData.fromRow(Map<String, dynamic> row) {
    final realName = AdminUserDetailController.realNameOf(row);
    final words = realName.split(' ').where((w) => w.isNotEmpty).toList();
    final initials = words.take(2).map((w) => w[0].toUpperCase()).join();
    final created = AdminUserDetailController.formatDate(row['created_at']);
    return _UserRowData(
      id: '${row['id']}',
      initials: initials.isEmpty ? '?' : initials,
      name: realName.isEmpty ? 'User #${row['id']}' : realName,
      phone: (row['phone'] as String?) ?? '-',
      role: AdminUsersController.displayRole(row['role'] as String?),
      status: AdminUsersController.displayStatus(row['status'] as String?),
      joined: created,
    );
  }

  const _UserRowData({
    required this.id,
    required this.initials,
    required this.name,
    required this.phone,
    required this.role,
    required this.status,
    required this.joined,
  });

  final String id;
  final String initials;
  final String name;
  final String phone;
  final String role;
  final String status;
  final String joined;
}
