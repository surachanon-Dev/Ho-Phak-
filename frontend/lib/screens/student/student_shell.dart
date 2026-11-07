import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../services/app_services.dart';
import '../chat_list_screen.dart';
import 'favorites_screen.dart';
import 'search_screen.dart';
import 'student_home_screen.dart';
import 'student_profile_screen.dart';

/// โครงหลักของนักศึกษา: หน้าแรก / รายการโปรด / แชท / โปรไฟล์
/// ปุ่มค้นหาอยู่กลางแถบล่าง (ตามดีไซน์)
class StudentShell extends StatefulWidget {
  const StudentShell({super.key, required this.services, required this.user});

  final AppServices services;
  final CurrentUser user;

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _index = 0;

  // เพิ่มค่าทุกครั้งที่เลือกแท็บ เพื่อให้แท็บนั้นโหลดข้อมูลใหม่ (แท็บอยู่ใน IndexedStack จึงไม่โหลดซ้ำเอง)
  int _favEpoch = 0;
  int _chatEpoch = 0;

  void _goTo(int i) => setState(() {
    _index = i;
    if (i == 1) _favEpoch++;
    if (i == 2) _chatEpoch++;
  });

  @override
  Widget build(BuildContext context) {
    final s = widget.services;
    final u = widget.user;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          StudentHomeScreen(services: s, user: u),
          FavoritesScreen(
            key: ValueKey('fav-$_favEpoch'),
            services: s,
            myUserId: u.id,
            onExplore: () => _goTo(0),
          ),
          ChatListScreen(
            key: ValueKey('chat-$_chatEpoch'),
            services: s,
            myUserId: u.id,
            asStudent: true,
          ),
          StudentProfileScreen(services: s, user: u),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goTo,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'หน้าแรก',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'โปรด',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'แชท',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'โปรไฟล์',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'ค้นหาหอพัก',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SearchScreen(services: s, myUserId: u.id),
          ),
        ),
        child: const Icon(Icons.search),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
