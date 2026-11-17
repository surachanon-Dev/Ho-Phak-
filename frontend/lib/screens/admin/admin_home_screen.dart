import 'package:flutter/material.dart';

import '../../controllers/admin_activity_log_controller.dart';
import '../../controllers/admin_dashboard_controller.dart';
import '../../services/admin_service.dart';
import '../../ui/error_handling.dart';
import '../../services/app_services.dart';
import 'admin_dorms_tab.dart';
import 'admin_logs_tab.dart';
import 'admin_moderation_tab.dart';
import 'admin_profile_tab.dart';
import 'admin_queue_tab.dart';
import 'admin_reviews_tab.dart';
import 'admin_settings_tab.dart';

/// โครงหลักของ Ho-Phak Admin Web + หน้า 02 · DASHBOARD (A-1 และ A-1b)
/// วางทับที่: ช่องที่ 1 ในโฟลเดอร์ admin (lib/screens/admin/admin_home_screen.dart)
/// แยกเมนู Users และ Amenities ให้เปิดคนละหน้ากันผ่านไฟล์ช่องที่ 3 ตัวเดียวกัน
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  // ลำดับเมนูซ้าย 8 รายการ (ตรงกับลำดับหน้าใน IndexedStack):
  // 0: Dashboard   1: Owner requests (แท็บ verification)   2: Dorms
  // 3: Users       4: Reviews   5: Activity log   6: Amenities   7: Settings
  // 8: Profile (เปิดจากไอคอนออกจากระบบด้านล่างแถบเมนู ไม่ได้อยู่ในรายการเมนู)
  int _menuIndex = 0;

  late final AdminDashboardController _dash;
  late final AdminActivityLogController _logs;

  @override
  void initState() {
    super.initState();
    final admin = AdminService(widget.services.api);
    _dash = AdminDashboardController(admin);
    _logs = AdminActivityLogController(admin);
    _dash.addListener(_onChanged);
    _logs.addListener(_onChanged);
    _dash.load().then((ok) {
      if (!ok && mounted && _dash.error != null) {
        showApiError(context, widget.services, _dash.error!);
      }
    });
    _logs.refresh();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _dash.removeListener(_onChanged);
    _logs.removeListener(_onChanged);
    _dash.dispose();
    _logs.dispose();
    super.dispose();
  }

  int get _dormsAwaitingCount => _dash.dormsAwaitingCount;
  int get _ownerRequestsCount => _dash.ownerRequestsCount;
  int get _reportedReviewsCount => _dash.reportedReviewsCount;
  int get _suspendedCount => _dash.suspendedCount;
  int get _totalWaiting => _dash.totalWaiting;
  bool get _allCaughtUp => _dash.allCaughtUp;

  /// กิจกรรมล่าสุดของแอดมิน (แสดงบน Dashboard 4 รายการ)
  List<_ActivityRowData> get _recentActivityRows => _logs.entries
      .take(4)
      .map(_activityRowFromLog)
      .toList();

  static _ActivityRowData _activityRowFromLog(Map<String, dynamic> e) {
    final action = (e['action'] as String?) ?? '';
    final approving = action.contains('approve') || action.contains('publish') ||
        action.contains('restore') || action.contains('create');
    final negative = action.contains('reject') || action.contains('hide') ||
        action.contains('suspend') || action.contains('delete');
    final target = '${e['target_type'] ?? ''} #${e['target_id'] ?? ''}'.trim();
    return _ActivityRowData(
      time: (e['created_at'] ?? '').toString(),
      admin: (e['admin_name'] as String?) ?? 'Admin',
      action: action,
      target: target,
      pillBg: approving
          ? const Color(0xFFDCFCE7)
          : negative
              ? const Color(0xFFFEE2E2)
              : const Color(0xFFE2E8F0),
      pillText: approving
          ? const Color(0xFF15803D)
          : negative
              ? const Color(0xFFB91C1C)
              : const Color(0xFF475569),
    );
  }

  int get _stackIndex => _menuIndex;

  String get _currentTitle {
    const titles = [
      'Dashboard',
      'Owner requests',
      'Dorms',
      'Users',
      'Reviews',
      'Activity log',
      'Amenities',
      'Settings',
      'Profile',
    ];
    return titles[_menuIndex];
  }

  static String _todayLabel() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final now = DateTime.now();
    return '${days[now.weekday - 1]} ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  void _selectMenu(int index) {
    setState(() => _menuIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.services;

    final stackPages = <Widget>[
      _DashboardView(
        allCaughtUp: _allCaughtUp,
        dormsAwaitingCount: _dormsAwaitingCount,
        reportedReviewsCount: _reportedReviewsCount,
        suspendedCount: _suspendedCount,
        suspendedDorms: _dash.suspendedDormsCount,
        suspendedAccounts: _dash.suspendedAccountsCount,
        totalWaiting: _totalWaiting,
        onSelectMenu: _selectMenu,
        activities: _recentActivityRows,
      ),
      AdminQueueTab(services: s, onChanged: () => _dash.load()), // 1: Owner requests (verification)
      AdminDormsTab(services: s, onChanged: () => _dash.load()), // 2: Dorms
      AdminModerationTab(services: s, showAmenities: false), // 3: Users
      AdminReviewsTab(services: s), // 4: Reviews
      AdminLogsTab(services: s), // 5: Activity log
      AdminModerationTab(services: s, showAmenities: true), // 6: Amenities
      AdminSettingsTab(services: s), // 7: Settings
      AdminProfileTab(services: s), // 8: Profile (ไอคอนออกจากระบบ)
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      body: Row(
        children: [
          // แถบเมนูซ้าย (Sidebar)
          Container(
            width: 220,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // โลโก้ Ho-Phak Admin dashboard
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0062D6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'H',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ho-Phak',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                height: 1.1,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Admin dashboard',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // รายการเมนูซ้าย
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    children: [
                      _SidebarItem(
                        icon: Icons.grid_view_outlined,
                        label: 'Dashboard',
                        selected: _menuIndex == 0,
                        onTap: () => _selectMenu(0),
                      ),
                      _SidebarItem(
                        icon: Icons.how_to_reg_outlined,
                        label: 'Owner requests',
                        badgeCount: _ownerRequestsCount,
                        selected: _menuIndex == 1,
                        onTap: () => _selectMenu(1),
                      ),
                      _SidebarItem(
                        icon: Icons.apartment_outlined,
                        label: 'Dorms',
                        badgeCount: _dormsAwaitingCount,
                        selected: _menuIndex == 2,
                        onTap: () => _selectMenu(2),
                      ),
                      _SidebarItem(
                        icon: Icons.people_outline,
                        label: 'Users',
                        selected: _menuIndex == 3,
                        onTap: () => _selectMenu(3),
                      ),
                      _SidebarItem(
                        icon: Icons.star_border,
                        label: 'Reviews',
                        badgeCount: _reportedReviewsCount,
                        selected: _menuIndex == 4,
                        onTap: () => _selectMenu(4),
                      ),
                      _SidebarItem(
                        icon: Icons.history,
                        label: 'Activity log',
                        selected: _menuIndex == 5,
                        onTap: () => _selectMenu(5),
                      ),
                      _SidebarItem(
                        icon: Icons.sell_outlined,
                        label: 'Amenities',
                        selected: _menuIndex == 6,
                        onTap: () => _selectMenu(6),
                      ),
                      _SidebarItem(
                        icon: Icons.tune,
                        label: 'Settings',
                        selected: _menuIndex == 7,
                        onTap: () => _selectMenu(7),
                      ),
                    ],
                  ),
                ),

                // ส่วนโปรไฟล์ Admin ด้านล่างซ้าย
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDBEAFE),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'AD',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0062D6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                height: 1.15,
                              ),
                            ),
                            Text(
                              'Administrator',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                height: 1.15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Profile / Sign out',
                        onPressed: () => _selectMenu(8),
                        icon: const Icon(
                          Icons.logout,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // พื้นที่เนื้อหาหลักด้านขวา
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // แถบด้านบน
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _currentTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _todayLabel(),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                // เนื้อหาของแต่ละหน้าจอ
                Expanded(
                  child: IndexedStack(
                    index: _stackIndex,
                    children: stackPages,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: selected ? const Color(0xFFE8F1FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected
                      ? const Color(0xFF0062D6)
                      : const Color(0xFF475569),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected
                          ? const Color(0xFF0062D6)
                          : const Color(0xFF334155),
                    ),
                  ),
                ),
                if (badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0062D6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({
    required this.allCaughtUp,
    required this.dormsAwaitingCount,
    required this.reportedReviewsCount,
    required this.suspendedCount,
    required this.suspendedDorms,
    required this.suspendedAccounts,
    required this.totalWaiting,
    required this.onSelectMenu,
    required this.activities,
  });

  final bool allCaughtUp;
  final int dormsAwaitingCount;
  final int reportedReviewsCount;
  final int suspendedCount;
  final int suspendedDorms;
  final int suspendedAccounts;
  final int totalWaiting;
  final ValueChanged<int> onSelectMenu;
  final List<_ActivityRowData> activities;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Good morning, Admin',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            allCaughtUp
                ? 'Nothing is waiting for you right now.'
                : '$totalWaiting items are waiting for your review.',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.apartment_outlined,
                  count: dormsAwaitingCount,
                  title: 'Dorms awaiting review',
                  subtitle:
                      allCaughtUp ? 'Nothing waiting' : '3 new · 2 changes',
                  onTap: () => onSelectMenu(3),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _MetricCard(
                  icon: Icons.error_outline,
                  count: reportedReviewsCount,
                  title: 'Reported reviews',
                  subtitle: allCaughtUp
                      ? 'Nothing waiting'
                      : 'Reported by owners',
                  onTap: () => onSelectMenu(5),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _MetricCard(
                  icon: Icons.block,
                  count: suspendedCount,
                  title: 'Suspended',
                  subtitle: allCaughtUp
                      ? 'Nothing waiting'
                      : '$suspendedDorms ${suspendedDorms == 1 ? 'dorm' : 'dorms'} · '
                          '$suspendedAccounts ${suspendedAccounts == 1 ? 'account' : 'accounts'}',
                  onTap: () => onSelectMenu(3),
                ),
              ),
            ],
          ),
          if (allCaughtUp) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.check,
                      size: 20,
                      color: Color(0xFF15803D),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'All caught up',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'New dorms and reviews will show up here.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text(
                      'Recent activity',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => onSelectMenu(5),
                      child: const Text(
                        'View all',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0062D6),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
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
                              flex: 2,
                              child: Text(
                                'TIME',
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
                                'ADMIN',
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
                                'ACTION',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Text(
                                'TARGET',
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
                      for (int i = 0; i < activities.length; i++) ...[
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  activities[i].time,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  activities[i].admin,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: activities[i].pillBg,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      activities[i].action,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: activities[i].pillText,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Text(
                                  activities[i].target,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF334155),
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
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.count,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final int count;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F1FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      icon,
                      size: 17,
                      color: const Color(0xFF0062D6),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityRowData {
  const _ActivityRowData({
    required this.time,
    required this.admin,
    required this.action,
    required this.target,
    required this.pillBg,
    required this.pillText,
  });

  final String time;
  final String admin;
  final String action;
  final String target;
  final Color pillBg;
  final Color pillText;
}