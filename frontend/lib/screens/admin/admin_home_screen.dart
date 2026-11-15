import 'package:flutter/material.dart';

import '../../services/app_services.dart';
import 'admin_logs_tab.dart';
import 'admin_moderation_tab.dart';
import 'admin_profile_tab.dart';
import 'admin_queue_tab.dart';
import 'admin_reviews_tab.dart';

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
  // ลำดับเมนูซ้าย 7 รายการ:
  // 0: Dashboard
  // 1: Dorms        (เชื่อมไปที่ AdminQueueTab)
  // 2: Users        (เชื่อมไปที่ AdminModerationTab -> showAmenities: false)
  // 3: Reviews      (เชื่อมไปที่ AdminReviewsTab)
  // 4: Activity log (เชื่อมไปที่ AdminLogsTab)
  // 5: Amenities    (เชื่อมไปที่ AdminModerationTab -> showAmenities: true)
  // 6: Settings     (เชื่อมไปที่ AdminProfileTab)
  int _menuIndex = 0;

  bool _allCaughtUp = false;

  int get _dormsAwaitingCount => _allCaughtUp ? 0 : 5;
  int get _reportedReviewsCount => _allCaughtUp ? 0 : 2;
  int get _suspendedCount => _allCaughtUp ? 0 : 2;

  int get _totalWaiting => _dormsAwaitingCount + _reportedReviewsCount;

  // แปลงเมนูซ้าย 7 รายการ ไปยังหน้าจอทั้ง 7 ใน IndexedStack
  int get _stackIndex => _menuIndex;

  String get _currentTitle {
    const titles = [
      'Dashboard',
      'Dorms',
      'Users',
      'Reviews',
      'Activity log',
      'Amenities',
      'Settings',
    ];
    return titles[_menuIndex];
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
        totalWaiting: _totalWaiting,
        onSelectMenu: _selectMenu,
      ),
      AdminQueueTab(services: s), // 1: Dorms
      AdminModerationTab(services: s, showAmenities: false), // 2: Users
      AdminReviewsTab(services: s), // 3: Reviews
      AdminLogsTab(services: s), // 4: Activity log
      AdminModerationTab(services: s, showAmenities: true), // 5: Amenities
      AdminProfileTab(services: s), // 6: Settings
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
                        icon: Icons.apartment_outlined,
                        label: 'Dorms',
                        badgeCount: _dormsAwaitingCount,
                        selected: _menuIndex == 1,
                        onTap: () => _selectMenu(1),
                      ),
                      _SidebarItem(
                        icon: Icons.people_outline,
                        label: 'Users',
                        selected: _menuIndex == 2,
                        onTap: () => _selectMenu(2),
                      ),
                      _SidebarItem(
                        icon: Icons.star_border,
                        label: 'Reviews',
                        badgeCount: _reportedReviewsCount,
                        selected: _menuIndex == 3,
                        onTap: () => _selectMenu(3),
                      ),
                      _SidebarItem(
                        icon: Icons.history,
                        label: 'Activity log',
                        selected: _menuIndex == 4,
                        onTap: () => _selectMenu(4),
                      ),
                      _SidebarItem(
                        icon: Icons.sell_outlined,
                        label: 'Amenities',
                        selected: _menuIndex == 5,
                        onTap: () => _selectMenu(5),
                      ),
                      _SidebarItem(
                        icon: Icons.tune,
                        label: 'Settings',
                        selected: _menuIndex == 6,
                        onTap: () => _selectMenu(6),
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
                        onPressed: () => _selectMenu(6),
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
                      if (_menuIndex == 0)
                        Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () =>
                                setState(() => _allCaughtUp = !_allCaughtUp),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                _allCaughtUp
                                    ? 'โหมด: A-1b (All caught up)'
                                    : 'โหมด: A-1 (มีงานรอ)',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                        ),
                      const Text(
                        'Sun 8 Nov 2026',
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
    required this.totalWaiting,
    required this.onSelectMenu,
  });

  final bool allCaughtUp;
  final int dormsAwaitingCount;
  final int reportedReviewsCount;
  final int suspendedCount;
  final int totalWaiting;
  final ValueChanged<int> onSelectMenu;

  static const List<_ActivityRowData> _recentActivities = [
    _ActivityRowData(
      time: 'Today 09:42',
      admin: 'Admin',
      action: 'dormitory.approve',
      target: 'หอพักบ้านสวนดอย',
      pillBg: Color(0xFFDCFCE7),
      pillText: Color(0xFF15803D),
    ),
    _ActivityRowData(
      time: 'Today 09:15',
      admin: 'Admin',
      action: 'review.hide',
      target: 'Review #31 · หอพักริมดอย',
      pillBg: Color(0xFFFEE2E2),
      pillText: Color(0xFFB91C1C),
    ),
    _ActivityRowData(
      time: 'Yesterday 16:40',
      admin: 'Admin',
      action: 'dormitory.suspend',
      target: 'หอพักสวนหลวง',
      pillBg: Color(0xFFFEF3C7),
      pillText: Color(0xFFB45309),
    ),
    _ActivityRowData(
      time: 'Yesterday 11:20',
      admin: 'Admin',
      action: 'amenity.create',
      target: 'Elevator',
      pillBg: Color(0xFFDBEAFE),
      pillText: Color(0xFF1D4ED8),
    ),
  ];

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
                  onTap: () => onSelectMenu(1),
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
                  onTap: () => onSelectMenu(3),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _MetricCard(
                  icon: Icons.block,
                  count: suspendedCount,
                  title: 'Suspended',
                  subtitle:
                      allCaughtUp ? 'Nothing waiting' : '1 dorm · 1 account',
                  onTap: () => onSelectMenu(2),
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
                      onTap: () => onSelectMenu(4),
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
                      for (int i = 0; i < _recentActivities.length; i++) ...[
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
                                  _recentActivities[i].time,
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
                                  _recentActivities[i].admin,
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
                                      color: _recentActivities[i].pillBg,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      _recentActivities[i].action,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: _recentActivities[i].pillText,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Text(
                                  _recentActivities[i].target,
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