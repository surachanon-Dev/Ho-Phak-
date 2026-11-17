import 'package:flutter/material.dart';

import 'package:hopak_frontend/shared/models/user.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/features/chat/chat_list/chat_list_screen.dart';
import 'package:hopak_frontend/features/notifications/notifications_screen.dart';
import 'package:hopak_frontend/features/student/favorites/favorites_screen.dart';
import 'package:hopak_frontend/features/student/map/student_map_screen.dart';
import 'package:hopak_frontend/features/student/search/search_screen.dart';
import 'package:hopak_frontend/features/student/home/student_home_screen.dart';
import 'package:hopak_frontend/features/student/profile/student_profile_screen.dart';

/// โครงหลักของนักศึกษา (ตามดีไซน์ Frontend-Big): 5 แท็บ
/// หน้าหลัก / ค้นหา / แผนที่ / รายการโปรด / โปรไฟล์
/// ปุ่มแชทและการแจ้งเตือนอยู่บน app bar ของทุกแท็บ
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

  int _index = 0;
  final _searchKey = GlobalKey<SearchScreenState>();

  // เพิ่มค่าทุกครั้งที่เลือกแท็บรายการโปรด เพื่อให้โหลดใหม่ (แท็บอยู่ใน IndexedStack จึงไม่โหลดซ้ำเอง)
  int _favEpoch = 0;

  void _goTo(int i) => setState(() {
    _index = i;
    if (i == _favTab) _favEpoch++;
  });

  /// จากหน้าแรก: สลับไปแท็บค้นหาแล้วตั้งตัวกรองตามที่กด
  void _openSearch({String? zone, String? sort}) {
    _goTo(_searchTab);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _searchKey.currentState?.applyQuick(zone: zone, sort: sort),
    );
  }

  void _push(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  List<Widget> _actions() => [
    IconButton(
      tooltip: 'ข้อความ',
      icon: const Icon(Icons.chat_bubble_outline),
      onPressed: () => _push(
        ChatListScreen(
          services: widget.services,
          myUserId: widget.user.id,
          asStudent: true,
        ),
      ),
    ),
    IconButton(
      tooltip: 'การแจ้งเตือน',
      icon: const Icon(Icons.notifications_none),
      onPressed: () => _push(NotificationsScreen(services: widget.services)),
    ),
    const SizedBox(width: 4),
  ];

  @override
  Widget build(BuildContext context) {
    final s = widget.services;
    final u = widget.user;
    final actions = _actions();
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          StudentHomeScreen(
            services: s,
            user: u,
            onOpenSearch: _openSearch,
            actions: actions,
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
            onExplore: () => _goTo(_searchTab),
            actions: actions,
          ),
          StudentProfileScreen(services: s, user: u, actions: actions),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goTo,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'หน้าหลัก',
          ),
          NavigationDestination(icon: Icon(Icons.search), label: 'ค้นหา'),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'แผนที่',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'รายการโปรด',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'โปรไฟล์',
          ),
        ],
      ),
    );
  }
}
