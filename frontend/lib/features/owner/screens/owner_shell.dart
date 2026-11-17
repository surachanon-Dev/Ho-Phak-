import 'package:flutter/material.dart';

import '../../../core/app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/models/user.dart';
import '../../chat/screens/chat_list_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'verification_screen.dart';

/// โครงหลักของเจ้าของหอพัก: แท็บ หอพัก / แชท / โปรไฟล์
/// จอแคบใช้แถบเมนูล่าง จอกว้างใช้แถบเมนูซ้าย
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

  static const _destinations = [
    (Icons.apartment_outlined, Icons.apartment_rounded, 'My Dorms'),
    (Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Chat'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  void _select(int i) => setState(() {
    _index = i;
    // โหลดแชทใหม่ทุกครั้งที่เปิดแท็บแชท
    if (i == 1) _chatEpoch++;
  });

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    if (!user.isVerified) {
      return VerificationScreen(services: widget.services, gate: true);
    }

    final pages = IndexedStack(
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
                      Icons.home_work_rounded,
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
