import 'package:flutter/material.dart';

import '../../core/utils/responsive.dart';

import 'activity_log/admin_activity_log_controller.dart';
import 'dashboard/admin_dashboard_controller.dart';
import 'services/admin_service.dart';
import '../../core/utils/error_handling.dart';
import '../../core/app_services.dart';
import 'dorms/admin_dorms_tab.dart';
import 'activity_log/admin_logs_tab.dart';
import 'amenities/admin_amenities_tab.dart';
import 'dashboard/admin_dashboard_view.dart';
import 'users/admin_users_tab.dart';
import 'profile/admin_profile_tab.dart';
import 'owner_requests/admin_queue_tab.dart';
import 'reviews/admin_reviews_tab.dart';
import 'settings/admin_settings_tab.dart';

/// โครงหลักของ Ho-Phak Admin Web: เมนูซ้าย + สลับหน้าตามเมนู
/// หน้า Dashboard อยู่ที่ dashboard/admin_dashboard_view.dart
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
  List<ActivityRowData> get _recentActivityRows =>
      _logs.entries.take(4).map(ActivityRowData.fromLog).toList();

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
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final now = DateTime.now();
    return '${days[now.weekday - 1]} ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _selectMenu(int index) {
    setState(() => _menuIndex = index);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(_scaffoldKey.currentContext!).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.services;

    final stackPages = <Widget>[
      AdminDashboardView(
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
      AdminQueueTab(
        services: s,
        onChanged: () => _dash.load(),
      ), // 1: Owner requests (verification)
      AdminDormsTab(services: s, onChanged: () => _dash.load()), // 2: Dorms
      AdminUsersTab(services: s), // 3: Users
      AdminReviewsTab(services: s), // 4: Reviews
      AdminLogsTab(services: s), // 5: Activity log
      AdminAmenitiesTab(services: s), // 6: Amenities
      AdminSettingsTab(services: s), // 7: Settings
      AdminProfileTab(services: s), // 8: Profile (ไอคอนออกจากระบบ)
    ];

    final wide = isWideLayout(context);

    // เมนูซ้าย: ถาวรบนจอกว้าง ใช้เป็น drawer บนจอแคบ
    final Widget sidebar = Container(
      width: 220,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
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
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // แถบด้านบน (บนจอแคบแสดงใน AppBar แทน)
        if (wide)
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
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
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: IndexedStack(index: _stackIndex, children: stackPages),
        ),
      ],
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF3F5F8),
      drawer: wide ? null : Drawer(width: 240, child: SafeArea(child: sidebar)),
      appBar: wide
          ? null
          : AppBar(
              title: Text(_currentTitle),
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F172A),
              elevation: 0,
            ),
      body: wide
          ? Row(
              children: [
                sidebar,
                Expanded(child: content),
              ],
            )
          : content,
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
