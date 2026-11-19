import 'package:flutter/material.dart';

import '../../../../core/app_services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../model/user.dart';
import '../../../chat/chat_list/view/chat_list_screen.dart';
import '../../../notifications/view/notifications_screen.dart';
import '../../profile/controller/student_badges_controller.dart';
import '../../favorites/view/favorites_screen.dart';
import '../../search/view/search_screen.dart';
import '../../home/view/student_home_screen.dart';
import '../../map/view/student_map_screen.dart';
import '../../profile/view/student_profile_screen.dart';

/// ปุ่มลัดเปิดแชทและการแจ้งเตือน (พร้อมจำนวนที่ยังไม่อ่าน) ส่งให้ทุกแท็บของนักศึกษา
class StudentShortcuts {
  const StudentShortcuts({
    required this.openChats,
    required this.openNotifications,
    this.unreadMessages = 0,
    this.unreadNotifications = 0,
  });

  final VoidCallback openChats;
  final VoidCallback openNotifications;
  final int unreadMessages;
  final int unreadNotifications;

  /// ไอคอนพร้อมตัวเลขที่ยังไม่อ่าน (เกิน 99 แสดง 99+)
  static Widget badged(IconData icon, int count) => Badge(
    isLabelVisible: count > 0,
    label: Text(count > 99 ? '99+' : '$count'),
    child: Icon(icon),
  );

  /// ปุ่มบน app bar
  List<Widget> appBarActions() => [
    IconButton(
      tooltip: 'Messages',
      icon: badged(Icons.chat_bubble_outline_rounded, unreadMessages),
      onPressed: openChats,
    ),
    IconButton(
      tooltip: 'Notifications',
      icon: badged(Icons.notifications_none_rounded, unreadNotifications),
      onPressed: openNotifications,
    ),
    const SizedBox(width: 8),
  ];
}

/// โครงหลักของนักศึกษา: หน้าหลัก / ค้นหา / แผนที่ / รายการโปรด / โปรไฟล์
/// จอแคบใช้แถบเมนูล่าง จอกว้างใช้แถบเมนูซ้าย (เหมือนฝั่ง owner)
class StudentShell extends StatefulWidget {
  const StudentShell({super.key, required this.services, required this.user});

  final AppServices services;
  final CurrentUser user;

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  static const _searchTab = 1;
  static const _favTab = 3;

  static const _destinations = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.search_rounded, Icons.search_rounded, 'Search'),
    (Icons.map_outlined, Icons.map_rounded, 'Map'),
    (Icons.favorite_border_rounded, Icons.favorite_rounded, 'Favorites'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  int _index = 0;
  final _searchKey = GlobalKey<SearchScreenState>();
  late final StudentBadgesController _badges;

  @override
  void initState() {
    super.initState();
    _badges = StudentBadgesController(
      chats: widget.services.chats,
      notifications: widget.services.notifications,
    );
    _badges.addListener(_onBadges);
    _badges.refresh();
  }

  void _onBadges() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _badges.removeListener(_onBadges);
    _badges.dispose();
    super.dispose();
  }

  // เพิ่มค่าทุกครั้งที่เปิดแท็บรายการโปรด เพื่อให้โหลดใหม่ (แท็บอยู่ใน IndexedStack จึงไม่โหลดซ้ำเอง)
  int _favEpoch = 0;

  void _select(int i) {
    setState(() {
      _index = i;
      if (i == _favTab) _favEpoch++;
    });
    _badges.refresh();
  }

  /// จากหน้าแรก: สลับไปแท็บค้นหาแล้วตั้งตัวกรองตามที่กด
  void _openSearch({String? zone, String? sort}) {
    _select(_searchTab);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _searchKey.currentState?.applyQuick(zone: zone, sort: sort),
    );
  }

  /// เปิดหน้าแชท/แจ้งเตือน แล้วนับที่ยังไม่อ่านใหม่เมื่อกลับมา
  Future<void> _push(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    _badges.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.services;
    final u = widget.user;
    final shortcuts = StudentShortcuts(
      openChats: () =>
          _push(ChatListScreen(services: s, myUserId: u.id, asStudent: true)),
      openNotifications: () => _push(NotificationsScreen(services: s)),
      unreadMessages: _badges.messages,
      unreadNotifications: _badges.notifications,
    );
    final actions = shortcuts.appBarActions();

    final pages = IndexedStack(
      index: _index,
      children: [
        StudentHomeScreen(
          services: s,
          user: u,
          onOpenSearch: _openSearch,
          shortcuts: shortcuts,
        ),
        SearchScreen(
          key: _searchKey,
          services: s,
          myUserId: u.id,
          actions: actions,
        ),
        StudentMapScreen(services: s, myUserId: u.id, actions: actions),
        FavoritesScreen(
          key: ValueKey('fav-$_favEpoch'),
          services: s,
          myUserId: u.id,
          onExplore: () => _select(_searchTab),
          actions: actions,
        ),
        StudentProfileScreen(services: s, user: u, actions: actions),
      ],
    );

    if (isWideLayout(context)) {
      return Scaffold(
        body: Row(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(right: BorderSide(color: AppColors.border)),
              ),
              child: NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: _select,
                backgroundColor: Colors.transparent,
                labelType: NavigationRailLabelType.all,
                indicatorColor: AppColors.primarySoft,
                minWidth: 92,
                groupAlignment: -0.85,
                selectedIconTheme: const IconThemeData(
                  color: AppColors.primary,
                ),
                unselectedIconTheme: const IconThemeData(
                  color: AppColors.textMuted,
                ),
                selectedLabelTextStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
                unselectedLabelTextStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
                leading: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
                destinations: [
                  for (final d in _destinations)
                    NavigationRailDestination(
                      icon: Icon(d.$1),
                      selectedIcon: Icon(d.$2),
                      label: Text(d.$3),
                    ),
                ],
              ),
            ),
            Expanded(child: pages),
          ],
        ),
      );
    }

    return Scaffold(
      body: pages,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _select,
          destinations: [
            for (final d in _destinations)
              NavigationDestination(
                icon: Icon(d.$1),
                selectedIcon: Icon(d.$2),
                label: d.$3,
              ),
          ],
        ),
      ),
    );
  }
}
