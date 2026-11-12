import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/badge_controller.dart';
import '../common/profile_view.dart';
import '../widgets/top_actions.dart';
import 'admin_dashboard_view.dart';
import 'admin_dorms_view.dart';
import 'admin_logs_view.dart';
import 'admin_reviews_view.dart';
import 'admin_users_view.dart';

/// Admin area – NavigationRail on wide screens (web), Drawer on phones
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminPage {
  const _AdminPage(this.label, this.icon, this.selected);
  final String label;
  final IconData icon;
  final IconData selected;
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const _pages = [
    _AdminPage('ภาพรวม', Icons.dashboard_outlined, Icons.dashboard),
    _AdminPage('หอพัก', Icons.apartment_outlined, Icons.apartment),
    _AdminPage('ผู้ใช้', Icons.people_outline, Icons.people),
    _AdminPage('รีวิว', Icons.rate_review_outlined, Icons.rate_review),
    _AdminPage('บันทึกการทำงาน', Icons.history_outlined, Icons.history),
    _AdminPage('โปรไฟล์', Icons.person_outline, Icons.person),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<BadgeController>().refresh());
  }

  void _go(int i) => setState(() => _index = i);

  Widget _body() => switch (_index) {
        0 => AdminDashboardView(onOpen: _go),
        1 => const AdminDormsView(),
        2 => const AdminUsersView(),
        3 => const AdminReviewsView(),
        4 => const AdminLogsView(),
        _ => const ProfileView(),
      };

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final body = KeyedSubtree(key: ValueKey(_index), child: _body());

    return Scaffold(
      appBar: AppBar(title: Text('ผู้ดูแลระบบ · ${_pages[_index].label}'), actions: topActions(context, chat: false)),
      drawer: wide
          ? null
          : NavigationDrawer(
              selectedIndex: _index,
              onDestinationSelected: (i) {
                Navigator.pop(context);
                _go(i);
              },
              children: [
                const Padding(padding: EdgeInsets.fromLTRB(28, 16, 16, 10), child: Text('Ho-Phak Admin', style: TextStyle(fontWeight: FontWeight.bold))),
                for (final p in _pages) NavigationDrawerDestination(icon: Icon(p.icon), selectedIcon: Icon(p.selected), label: Text(p.label)),
              ],
            ),
      body: wide
          ? Row(children: [
              NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: _go,
                labelType: NavigationRailLabelType.all,
                destinations: [
                  for (final p in _pages) NavigationRailDestination(icon: Icon(p.icon), selectedIcon: Icon(p.selected), label: Text(p.label)),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ])
          : body,
    );
  }
}
