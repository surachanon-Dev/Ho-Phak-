import 'package:flutter/material.dart';

import '../../services/app_services.dart';

/// รวมทั้งหน้า 05 · USERS (A-4 ถึง A-4d) และหน้า 07 · Amenities (A-7 ถึง A-7b) ไว้ในไฟล์เดียว
/// วางทับที่: ช่องที่ 3 ในโฟลเดอร์ admin (lib/screens/admin/admin_moderation_tab.dart)
/// - เมื่อคลิกเมนู Users จะแสดงหน้า Users (showAmenities: false)
/// - เมื่อคลิกเมนู Amenities จะแสดงหน้า Amenities (showAmenities: true)
class AdminModerationTab extends StatefulWidget {
  const AdminModerationTab({
    super.key,
    required this.services,
    this.showAmenities = false,
  });

  final AppServices services;
  final bool showAmenities;

  @override
  State<AdminModerationTab> createState() => _AdminModerationTabState();
}

class _AdminModerationTabState extends State<AdminModerationTab> {
  // ===========================================================================
  // State สำหรับหน้า 05 · USERS
  // ===========================================================================
  String _searchQuery = '';
  String _roleFilter = 'All roles';
  String _statusFilter = 'All statuses';
  _UserRowData? _selectedUser;

  final List<_UserRowData> _users = [
    _UserRowData(
      id: 'u-1',
      initials: 'SJ',
      name: 'Somchai Jaidee',
      phone: '081-234-5678',
      role: 'Owner',
      status: 'Active',
      joined: '2 Sep 2026',
      lastUpdated: 'Today 07:58',
      verifiedInfo: 'Yes · approved 3 Sep 2026',
      dormCount: 6,
      dorms: const [
        _OwnerDormStatus(name: 'หอพักริมดอย', status: 'Changes pending'),
        _OwnerDormStatus(name: 'หอพักสวนหลวง', status: 'Suspended'),
        _OwnerDormStatus(name: 'บ้านปลายฟ้า', status: 'Hidden'),
        _OwnerDormStatus(name: 'หอพักบ้านสวนดอย', status: 'Pending review'),
        _OwnerDormStatus(name: 'บ้านดอยงาม', status: 'Rejected'),
        _OwnerDormStatus(name: 'ดอยคำ เรสซิเดนซ์', status: 'Published'),
      ],
    ),
    _UserRowData(
      id: 'u-2',
      initials: 'KS',
      name: 'Kanya Srisuk',
      phone: '084-667-0921',
      role: 'Owner',
      status: 'Active',
      joined: '15 Aug 2026',
      lastUpdated: 'Yesterday 14:20',
      verifiedInfo: 'Yes · approved 16 Aug 2026',
      dormCount: 3,
      dorms: const [
        _OwnerDormStatus(name: 'หอพักบ้านสวนดอย', status: 'Published'),
        _OwnerDormStatus(name: 'เคียงดอย แมนชั่น', status: 'Published'),
        _OwnerDormStatus(name: 'บ้านสุขใจ', status: 'Pending review'),
      ],
    ),
    _UserRowData(
      id: 'u-3',
      initials: 'PW',
      name: 'Pimchanok Wongsa',
      phone: '089-552-1043',
      role: 'Student',
      status: 'Active',
      joined: '20 Oct 2026',
      lastUpdated: 'Today 09:10',
    ),
    _UserRowData(
      id: 'u-4',
      initials: 'BT',
      name: 'Big Thanawat',
      phone: '092-310-4456',
      role: 'Student',
      status: 'Active',
      joined: '1 Oct 2026',
      lastUpdated: '3 Nov 2026',
    ),
    _UserRowData(
      id: 'u-5',
      initials: 'PB',
      name: 'Prasert Boonmee',
      phone: '087-901-2234',
      role: 'Owner',
      status: 'Suspended',
      joined: '3 Jul 2026',
      lastUpdated: '7 Nov 2026',
      verifiedInfo: 'Yes · approved 4 Jul 2026',
      suspendedAt: '7 Nov 2026 16:40',
      suspensionReason: 'Repeated reports of misleading photos.',
      dormCount: 1,
      dorms: const [
        _OwnerDormStatus(name: 'ประเสริฐ เพลส', status: 'Suspended'),
      ],
    ),
    _UserRowData(
      id: 'u-6',
      initials: 'NT',
      name: 'Narin Thongdee',
      phone: '089-111-2233',
      role: 'Student',
      status: 'Active',
      joined: '2 Sep 2026',
      lastUpdated: 'Today 07:58',
    ),
    _UserRowData(
      id: 'u-7',
      initials: 'AD',
      name: 'Admin',
      phone: '08X-XXX-XXXX',
      role: 'Admin',
      status: 'Active',
      joined: '1 Jun 2026',
      lastUpdated: 'Today 08:00',
    ),
    _UserRowData(
      id: 'u-8',
      initials: 'WP',
      name: 'Wichai Phrom',
      phone: '095-221-4410',
      role: 'Owner',
      status: 'Active',
      joined: '12 Jun 2026',
      lastUpdated: '2 Nov 2026',
      verifiedInfo: 'Yes · approved 13 Jun 2026',
      dormCount: 2,
      dorms: const [
        _OwnerDormStatus(name: 'วิชัย การ์เด้น', status: 'Published'),
        _OwnerDormStatus(name: 'วิชัย พาร์ค', status: 'Published'),
      ],
    ),
  ];

  // ===========================================================================
  // State สำหรับหน้า 07 · Amenities
  // ===========================================================================
  final List<_AmenityItem> _amenities = [
    const _AmenityItem(
      id: 'am-1',
      name: 'Pets allowed',
      usedByCount: 3,
      addedLabel: 'Seed (D-45)',
    ),
    const _AmenityItem(
      id: 'am-2',
      name: 'Parking',
      usedByCount: 7,
      addedLabel: 'Seed (D-45)',
    ),
    const _AmenityItem(
      id: 'am-3',
      name: 'Washing machine',
      usedByCount: 5,
      addedLabel: 'Seed (D-45)',
    ),
    const _AmenityItem(
      id: 'am-4',
      name: 'Elevator',
      usedByCount: 2,
      addedLabel: 'Yesterday',
    ),
    const _AmenityItem(
      id: 'am-5',
      name: 'Wi-Fi',
      usedByCount: 11,
      addedLabel: '1 Nov 2026',
    ),
    const _AmenityItem(
      id: 'am-6',
      name: 'CCTV',
      usedByCount: 6,
      addedLabel: '1 Nov 2026',
    ),
    const _AmenityItem(
      id: 'am-7',
      name: 'Key card',
      usedByCount: 4,
      addedLabel: '1 Nov 2026',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.showAmenities) {
      return _buildAmenitiesView();
    }
    if (_selectedUser != null) {
      return _buildUserDetailView(_selectedUser!);
    }
    return _buildUsersListView();
  }

  // ===========================================================================
  // ส่วนที่ 1: โค้ดของ 05 · USERS (A-4, A-4a, A-4b, A-4c, A-4d)
  // ===========================================================================
  Future<void> _showSuspendDialog(_UserRowData user) async {
    final controller = TextEditingController(
      text: 'Repeated reports of fake listings. Please contact admin.',
    );

    final reason = await showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final currentLength = controller.text.length;
            final canSubmit =
                controller.text.trim().isNotEmpty && currentLength <= 300;

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Container(
                width: 420,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suspend ${user.name}?',
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user.role == 'Owner'
                          ? 'They will not be able to sign in until you reactivate the account. Their dorms are not changed.'
                          : 'They will not be able to sign in until you reactivate the account.',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Reason (required)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: controller,
                      maxLines: 3,
                      maxLength: 300,
                      onChanged: (_) => setDialogState(() {}),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: const EdgeInsets.all(12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF0062D6),
                            width: 1.4,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF0062D6),
                            width: 1.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currentLength / 300',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF334155),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: canSubmit
                              ? () => Navigator.of(ctx)
                                  .pop(controller.text.trim())
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC92A2A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Suspend',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (reason != null && mounted) {
      setState(() {
        final idx = _users.indexWhere((u) => u.id == user.id);
        if (idx != -1) {
          final updated = user.copyWith(
            status: 'Suspended',
            suspendedAt: '7 Nov 2026 16:40',
            suspensionReason: reason,
          );
          _users[idx] = updated;
          _selectedUser = updated;
        }
      });
    }
  }

  void _liftSuspension(_UserRowData user) {
    setState(() {
      final idx = _users.indexWhere((u) => u.id == user.id);
      if (idx != -1) {
        final updated = user.copyWith(
          status: 'Active',
          suspendedAt: null,
          suspensionReason: null,
        );
        _users[idx] = updated;
        _selectedUser = updated;
      }
    });
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
          Row(
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
              _FilterDropdown(
                value: _roleFilter,
                items: const ['All roles', 'Owner', 'Student', 'Admin'],
                onChanged: (v) {
                  if (v != null) setState(() => _roleFilter = v);
                },
              ),
              const SizedBox(width: 10),
              _FilterDropdown(
                value: _statusFilter,
                items: const ['All statuses', 'Active', 'Suspended'],
                onChanged: (v) {
                  if (v != null) setState(() => _statusFilter = v);
                },
              ),
              const Spacer(),
              const Text(
                '2,845 users',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                            child: _RolePill(role: filtered[i].role),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _UserStatusPill(status: filtered[i].status),
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
                            filtered[i].role == 'Owner'
                                ? '${filtered[i].dormCount}'
                                : '—',
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
                                      () => _selectedUser = filtered[i],
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
          const SizedBox(height: 14),
          Row(
            children: [
              const Text(
                'Showing 1–20 of 2,845',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 12),
              _SmallPageButton(icon: Icons.chevron_left, onTap: () {}),
              const SizedBox(width: 6),
              _SmallPageButton(icon: Icons.chevron_right, onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserDetailView(_UserRowData user) {
    final isOwner = user.role == 'Owner';
    final isSuspended = user.status == 'Suspended';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => setState(() => _selectedUser = null),
                child: const Text(
                  'Users',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const Text(
                ' / ',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _selectedUser = null),
                icon: const Icon(Icons.arrow_back, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              const Text(
                'User detail',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (isSuspended) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFDECEC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF8CACA)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.block,
                      size: 17,
                      color: Color(0xFFC92A2A),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account suspended by Admin · ${user.suspendedAt ?? "7 Nov 2026 16:40"}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFC92A2A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Reason: ${user.suspensionReason ?? "Repeated reports of misleading photos."} · Sign-in is blocked',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFC92A2A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (isOwner)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: _buildUserInfoCard(user),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: _buildOwnerDormsCard(user),
                ),
              ],
            )
          else
            SizedBox(
              width: 440,
              child: _buildUserInfoCard(user),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Color(0xFF0062D6),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isSuspended
                        ? 'Lifting the suspension lets this owner sign in again. Their dorms keep their current status (D-94).'
                        : (isOwner
                            ? 'Suspending blocks sign-in only. Their dorms keep their status — suspend a dorm separately if needed (D-94).'
                            : 'Suspending blocks sign-in only. Their reviews and favourites stay (D-94).'),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                if (isSuspended)
                  ElevatedButton(
                    onPressed: () => _liftSuspension(user),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0062D6),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Lift suspension',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  OutlinedButton(
                    onPressed: () => _showSuspendDialog(user),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFC92A2A),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Suspend account',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(_UserRowData user) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFDBEAFE),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  user.initials,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0062D6),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _RolePill(role: user.role),
                        const SizedBox(width: 6),
                        _UserStatusPill(status: user.status),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _UserKeyValueRow(label: 'Phone', value: user.phone),
          if (user.role == 'Owner') ...[
            const Divider(height: 22, color: Color(0xFFF1F5F9)),
            _UserKeyValueRow(
              label: 'Verified owner',
              value: user.verifiedInfo ?? 'Yes · approved 3 Sep 2026',
            ),
          ],
          const Divider(height: 22, color: Color(0xFFF1F5F9)),
          _UserKeyValueRow(label: 'Joined', value: user.joined),
          const Divider(height: 22, color: Color(0xFFF1F5F9)),
          _UserKeyValueRow(label: 'Last updated', value: user.lastUpdated),
        ],
      ),
    );
  }

  Widget _buildOwnerDormsCard(_UserRowData user) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dorms (${user.dorms.length})',
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(7),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'DORM',
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
                    ],
                  ),
                ),
                for (int i = 0; i < user.dorms.length; i++) ...[
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            user.dorms[i].name,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _DormStatusBadge(
                              status: user.dorms[i].status,
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
        ],
      ),
    );
  }

  // ===========================================================================
  // ส่วนที่ 2: โค้ดของ 07 · Amenities (A-7, A-7a, A-7b)
  // ===========================================================================
  Future<void> _showAddOrEditAmenityDialog({_AmenityItem? existing}) async {
    final isEdit = existing != null;
    final controller = TextEditingController(
      text: existing?.name ?? 'Air conditioner',
    );
    String? errorText;

    final savedName = await showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            void submit() {
              final trimmed = controller.text.trim();
              if (trimmed.isEmpty) {
                setDialogState(() {
                  errorText = 'Please enter an amenity name.';
                });
                return;
              }
              final duplicate = _amenities.any(
                (a) =>
                    a.id != existing?.id &&
                    a.name.toLowerCase() == trimmed.toLowerCase(),
              );
              if (duplicate) {
                setDialogState(() {
                  errorText = 'This amenity name already exists.';
                });
                return;
              }
              Navigator.of(ctx).pop(trimmed);
            }

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Container(
                width: 380,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? 'Edit amenity' : 'Add amenity',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Name',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      onChanged: (_) {
                        if (errorText != null) {
                          setDialogState(() => errorText = null);
                        }
                      },
                      onSubmitted: (_) => submit(),
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Air conditioner',
                        hintStyle: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF94A3B8),
                        ),
                        errorText: errorText,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF0062D6),
                            width: 1.4,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF0062D6),
                            width: 1.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Names must be unique. Editing a name updates every dorm that uses it.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF334155),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0062D6),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (savedName != null && mounted) {
      setState(() {
        if (isEdit) {
          final idx = _amenities.indexWhere((a) => a.id == existing.id);
          if (idx != -1) {
            _amenities[idx] = existing.copyWith(name: savedName);
          }
        } else {
          _amenities.add(
            _AmenityItem(
              id: 'am-${DateTime.now().millisecondsSinceEpoch}',
              name: savedName,
              usedByCount: 0,
              addedLabel: 'Today',
            ),
          );
        }
      });
    }
  }

  Future<void> _showDeleteAmenityDialog(_AmenityItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Container(
            width: 390,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Color(0xFFC92A2A),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Delete amenity?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '"${item.name}" is used by ${item.usedByCount} dorms. It will be removed from those dorms too. This cannot be undone.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF334155),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC92A2A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true && mounted) {
      setState(() {
        _amenities.removeWhere((a) => a.id == item.id);
      });
    }
  }

  Widget _buildAmenitiesView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Owners pick from this list when they add or edit a dorm.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => _showAddOrEditAmenityDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0062D6),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '+ Add amenity',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                        flex: 5,
                        child: Text(
                          'NAME',
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
                          'USED BY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'ADDED',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      SizedBox(width: 96),
                    ],
                  ),
                ),
                for (int i = 0; i < _amenities.length; i++) ...[
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text(
                            _amenities[i].name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${_amenities[i].usedByCount} dorms',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            _amenities[i].addedLabel,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 96,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(4),
                                onTap: () => _showAddOrEditAmenityDialog(
                                  existing: _amenities[i],
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    'Edit',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0062D6),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              InkWell(
                                borderRadius: BorderRadius.circular(4),
                                onTap: () =>
                                    _showDeleteAmenityDialog(_amenities[i]),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFC92A2A),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserRowData {
  const _UserRowData({
    required this.id,
    required this.initials,
    required this.name,
    required this.phone,
    required this.role,
    required this.status,
    required this.joined,
    required this.lastUpdated,
    this.verifiedInfo,
    this.suspendedAt,
    this.suspensionReason,
    this.dormCount = 0,
    this.dorms = const [],
  });

  final String id;
  final String initials;
  final String name;
  final String phone;
  final String role;
  final String status;
  final String joined;
  final String lastUpdated;
  final String? verifiedInfo;
  final String? suspendedAt;
  final String? suspensionReason;
  final int dormCount;
  final List<_OwnerDormStatus> dorms;

  _UserRowData copyWith({
    String? status,
    String? suspendedAt,
    String? suspensionReason,
  }) {
    return _UserRowData(
      id: id,
      initials: initials,
      name: name,
      phone: phone,
      role: role,
      status: status ?? this.status,
      joined: joined,
      lastUpdated: lastUpdated,
      verifiedInfo: verifiedInfo,
      suspendedAt: suspendedAt,
      suspensionReason: suspensionReason,
      dormCount: dormCount,
      dorms: dorms,
    );
  }
}

class _OwnerDormStatus {
  const _OwnerDormStatus({
    required this.name,
    required this.status,
  });

  final String name;
  final String status;
}

class _AmenityItem {
  const _AmenityItem({
    required this.id,
    required this.name,
    required this.usedByCount,
    required this.addedLabel,
  });

  final String id;
  final String name;
  final int usedByCount;
  final String addedLabel;

  _AmenityItem copyWith({
    String? name,
    int? usedByCount,
    String? addedLabel,
  }) {
    return _AmenityItem(
      id: id,
      name: name ?? this.name,
      usedByCount: usedByCount ?? this.usedByCount,
      addedLabel: addedLabel ?? this.addedLabel,
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Padding(
            padding: EdgeInsets.only(left: 6),
            child: Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Color(0xFF475569),
            ),
          ),
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0F172A),
          ),
          onChanged: onChanged,
          items: [
            for (final item in items)
              DropdownMenuItem(
                value: item,
                child: Text(item),
              ),
          ],
        ),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    if (role == 'Owner') {
      bg = const Color(0xFFDBEAFE);
      fg = const Color(0xFF1D4ED8);
    } else if (role == 'Admin') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFB45309);
    } else {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class _UserStatusPill extends StatelessWidget {
  const _UserStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isSuspended = status == 'Suspended';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2.5),
      decoration: BoxDecoration(
        color: isSuspended ? const Color(0xFFC92A2A) : const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isSuspended ? Colors.white : const Color(0xFF15803D),
        ),
      ),
    );
  }
}

class _DormStatusBadge extends StatelessWidget {
  const _DormStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case 'Changes pending':
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1D4ED8);
        break;
      case 'Suspended':
        bg = const Color(0xFFC92A2A);
        fg = Colors.white;
        break;
      case 'Hidden':
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
        break;
      case 'Pending review':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        break;
      case 'Rejected':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        break;
      case 'Published':
      default:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class _UserKeyValueRow extends StatelessWidget {
  const _UserKeyValueRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }
}

class _SmallPageButton extends StatelessWidget {
  const _SmallPageButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 16,
          color: const Color(0xFF64748B),
        ),
      ),
    );
  }
}