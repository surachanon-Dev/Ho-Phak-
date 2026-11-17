import 'package:flutter/material.dart';

import 'package:hopak_frontend/shared/models/user.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/features/chat/chat_list/chat_list_screen.dart';
import 'package:hopak_frontend/features/owner/dashboard/dashboard_screen.dart';
import 'package:hopak_frontend/features/owner/profile/profile_screen.dart';
import 'package:hopak_frontend/features/owner/verification/verification_screen.dart';

/// โครงหลักของเจ้าของหอพัก: แท็บ หอพัก / แชท / โปรไฟล์
/// ถ้ายังไม่ได้ยืนยันตัวตน จะแสดงหน้ายืนยันแทนทั้งหมด
class OwnerShell extends StatefulWidget {
  const OwnerShell({super.key, required this.services, required this.user});

  final AppServices services;
  final CurrentUser user;

  @override
  State<OwnerShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<OwnerShell> {
  int _index = 0;
  int _chatEpoch = 0;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    if (!user.isVerified) {
      return VerificationScreen(services: widget.services, gate: true);
    }

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          DashboardScreen(services: widget.services),
          ChatListScreen(
            key: ValueKey('owner-chat-$_chatEpoch'),
            services: widget.services,
            myUserId: user.id,
          ),
          ProfileScreen(services: widget.services, user: user),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() {
          _index = i;
          // โหลดแชทใหม่ทุกครั้งที่เปิดแท็บแชท
          if (i == 1) _chatEpoch++;
        }),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.apartment_outlined),
            selectedIcon: Icon(Icons.apartment),
            label: 'My Dorms',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
