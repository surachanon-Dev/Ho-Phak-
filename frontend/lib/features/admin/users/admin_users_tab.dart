import 'package:flutter/material.dart';

import '../../../core/app_services.dart';
import '../../../core/utils/error_handling.dart';
import '../../../core/utils/responsive.dart';
import '../services/admin_service.dart';
import '../user_detail/admin_user_detail_controller.dart';
import '../user_detail/admin_user_detail_screen.dart';
import 'admin_users_controller.dart';
import 'widgets/user_list_widgets.dart';

/// หน้า 05 · USERS (A-4 ถึง A-4d): รายการผู้ใช้ ค้นหา/กรอง และเปิดรายละเอียด
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

  /// รายการผู้ใช้แบบการ์ดสำหรับจอแคบ (กด View เพื่อเปิดรายละเอียด)
  Widget _userCards(List<_UserRowData> users) {
    if (users.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text('No users', style: TextStyle(color: Color(0xFF64748B))),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final u in users)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              u.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              u.phone,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (u.role != 'Admin')
                        TextButton(
                          onPressed: () =>
                              setState(() => _selectedUserId = u.id),
                          child: const Text('View'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      RolePill(role: u.role),
                      UserStatusPill(status: u.status),
                      Text(
                        'Joined ${u.joined}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 240,
                height: 36,
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: 'Search name or phone...',
                    hintStyle: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF0062D6)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilterDropdown(
                value: _roleFilter,
                items: const ['All roles', 'Owner', 'Student', 'Admin'],
                onChanged: (v) {
                  if (v != null) setState(() => _roleFilter = v);
                },
              ),
              const SizedBox(width: 10),
              FilterDropdown(
                value: _statusFilter,
                items: const ['All statuses', 'Active', 'Suspended'],
                onChanged: (v) {
                  if (v != null) setState(() => _statusFilter = v);
                },
              ),
              Text(
                '${filtered.length} users',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isWideLayout(context))
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(11),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            'USER',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'ROLE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'STATUS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'JOINED',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'DORMS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        SizedBox(width: 60),
                      ],
                    ),
                  ),
                  for (int i = 0; i < filtered.length; i++) ...[
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 13,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  filtered[i].name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  filtered[i].phone,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: RolePill(role: filtered[i].role),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: UserStatusPill(status: filtered[i].status),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              filtered[i].joined,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '—',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 60,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: filtered[i].role == 'Admin'
                                  ? const Text(
                                      '—',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    )
                                  : InkWell(
                                      borderRadius: BorderRadius.circular(4),
                                      onTap: () => setState(
                                        () => _selectedUserId = filtered[i].id,
                                      ),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        child: Text(
                                          'View',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF0062D6),
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (!isWideLayout(context)) _userCards(filtered),
          const SizedBox(height: 14),
          Text(
            'Showing ${filtered.length} of ${_users.length}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
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
