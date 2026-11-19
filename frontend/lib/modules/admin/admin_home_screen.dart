import 'package:flutter/material.dart';

import '../../app/session.dart';
import '../../core/app_services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import 'activity_log/admin_activity_log_controller.dart';
import 'activity_log/admin_logs_tab.dart';
import 'amenities/admin_amenities_tab.dart';
import 'dashboard/admin_dashboard_controller.dart';
import 'dashboard/admin_dashboard_view.dart';
import 'dorms/admin_dorms_tab.dart';
import 'owner_requests/admin_queue_tab.dart';
import 'profile/admin_profile_tab.dart';
import 'reviews/admin_reviews_tab.dart';
import 'services/admin_service.dart';
import 'settings/admin_settings_tab.dart';
import 'users/admin_users_tab.dart';

/// โครงหลักของ Ho-Phak Admin: เมนูซ้ายสีกรมท่า + สลับหน้าตามเมนู
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
  // 8: Profile (เปิดจากการ์ดโปรไฟล์ด้านล่างแถบเมนู ไม่ได้อยู่ในรายการเมนู)
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

  /// กิจกรรมล่าสุดของแอดมิน (แสดงบน Dashboard 5 รายการ)
  List<ActivityRowData> get _recentActivityRows =>
      _logs.entries.take(5).map(ActivityRowData.fromLog).toList();

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
        ownerRequestsCount: _ownerRequestsCount,
        reportedReviewsCount: _reportedReviewsCount,
        suspendedCount: _suspendedCount,
        suspendedDorms: _dash.suspendedDormsCount,
        suspendedAccounts: _dash.suspendedAccountsCount,
        totalWaiting: _totalWaiting,
        loading: _dash.loading,
        onRefresh: () async {
          await Future.wait([_dash.load(), _logs.refresh()]);
        },
        onSelectMenu: _selectMenu,
        activities: _recentActivityRows,
      ),
      AdminQueueTab(services: s, onChanged: () => _dash.load()), // 1
      AdminDormsTab(services: s, onChanged: () => _dash.load()), // 2
      AdminUsersTab(services: s), // 3
      AdminReviewsTab(services: s), // 4
      AdminLogsTab(services: s), // 5
      AdminAmenitiesTab(services: s), // 6
      AdminSettingsTab(services: s), // 7
      AdminProfileTab(services: s), // 8
    ];

    final wide = isWideLayout(context);

    final items = <_MenuEntry>[
      const _MenuEntry(Icons.space_dashboard_outlined, 'Dashboard'),
      _MenuEntry(
        Icons.how_to_reg_outlined,
        'Owner requests',
        badge: _ownerRequestsCount,
      ),
      _MenuEntry(Icons.apartment_outlined, 'Dorms', badge: _dormsAwaitingCount),
      const _MenuEntry(Icons.people_alt_outlined, 'Users'),
      _MenuEntry(
        Icons.star_outline_rounded,
        'Reviews',
        badge: _reportedReviewsCount,
      ),
      const _MenuEntry(Icons.history_rounded, 'Activity log'),
      const _MenuEntry(Icons.sell_outlined, 'Amenities'),
      const _MenuEntry(Icons.tune_rounded, 'Settings'),
    ];

    // เมนูซ้าย: ถาวรบนจอกว้าง ใช้เป็น drawer บนจอแคบ
    final Widget sidebar = Container(
      width: 248,
      color: AppColors.sidebar,
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SidebarLogo(),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 4, 22, 8),
              child: Text(
                'MENU',
                style: TextStyle(
                  fontSize: 10.5,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6E739A),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (var i = 0; i < items.length; i++)
                    _SidebarItem(
                      icon: items[i].icon,
                      label: items[i].label,
                      badgeCount: items[i].badge,
                      selected: _menuIndex == i,
                      onTap: () => _selectMenu(i),
                    ),
                ],
              ),
            ),
            _SidebarProfile(
              selected: _menuIndex == 8,
              onTap: () => _selectMenu(8),
            ),
          ],
        ),
      ),
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // แถบด้านบน (บนจอแคบแสดงใน AppBar แทน)
        if (wide)
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Text(
                  _currentTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const Spacer(),
                _DatePill(label: _todayLabel()),
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
      backgroundColor: AppColors.page,
      drawer: wide
          ? null
          : Drawer(
              width: 260,
              backgroundColor: AppColors.sidebar,
              child: sidebar,
            ),
      appBar: wide
          ? null
          : AppBar(
              title: Text(_currentTitle),
              backgroundColor: AppColors.surface,
              shape: const Border(bottom: BorderSide(color: AppColors.border)),
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

class _MenuEntry {
  const _MenuEntry(this.icon, this.label, {this.badge = 0});

  final IconData icon;
  final String label;
  final int badge;
}

class _SidebarLogo extends StatelessWidget {
  const _SidebarLogo();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.home_work_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ho-Phak',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Admin dashboard',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.sidebarText,
                    height: 1.1,
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

class _SidebarProfile extends StatelessWidget {
  const _SidebarProfile({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Material(
        color: selected ? AppColors.sidebarHover : const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    gradient: AppColors.brandGradient,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'AD',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
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
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.15,
                        ),
                      ),
                      Text(
                        'Administrator',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.sidebarText,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Profile / Sign out',
                  onPressed: onTap,
                  icon: const Icon(
                    Icons.logout_rounded,
                    size: 18,
                    color: AppColors.sidebarText,
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

class _DatePill extends StatelessWidget {
  const _DatePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 14,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textBody,
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
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          hoverColor: AppColors.sidebarHover,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: selected ? Colors.white : AppColors.sidebarText,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? Colors.white : AppColors.sidebarText,
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
                      color: selected ? Colors.white : const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: selected
                            ? AppColors.primary
                            : const Color(0xFF1F1300),
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
