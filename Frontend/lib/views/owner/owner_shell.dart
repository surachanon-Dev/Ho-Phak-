import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/badge_controller.dart';
import '../../controllers/owner_controller.dart';
import '../common/profile_view.dart';
import '../widgets/top_actions.dart';
import 'dorm_form_view.dart';
import 'owner_dashboard_view.dart';
import 'owner_dorms_view.dart';
import 'owner_reviews_view.dart';

/// Owner area – dashboard / my dorms / reviews / profile
class OwnerShell extends StatefulWidget {
  const OwnerShell({super.key});

  @override
  State<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends State<OwnerShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => refreshAll(context));
  }

  static const _titles = ['หน้าหลักเจ้าของหอ', 'หอพักของฉัน', 'รีวิวหอพักของฉัน', 'โปรไฟล์'];

  Future<void> _add() async {
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const DormFormView()));
    if (saved == true && mounted) {
      setState(() => _index = 1);
      refreshAll(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index]), actions: topActions(context)),
      body: IndexedStack(index: _index, children: [
        OwnerDashboardView(onOpenDorms: () => setState(() => _index = 1)),
        const OwnerDormsView(),
        const OwnerReviewsView(),
        const ProfileView(),
      ]),
      floatingActionButton: _index <= 1
          ? FloatingActionButton.extended(
              key: const Key('add_dorm'),
              onPressed: _add,
              icon: const Icon(Icons.add_home_outlined),
              label: const Text('เพิ่มหอพัก'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
          if (i <= 1) refreshAll(context);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'หน้าหลัก'),
          NavigationDestination(icon: Icon(Icons.apartment_outlined), selectedIcon: Icon(Icons.apartment), label: 'หอพัก'),
          NavigationDestination(icon: Icon(Icons.rate_review_outlined), selectedIcon: Icon(Icons.rate_review), label: 'รีวิว'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'โปรไฟล์'),
        ],
      ),
    );
  }
}

/// Reload everything the owner screens show (stats, dorms, badges)
void refreshAll(BuildContext context) {
  context.read<OwnerController>().refresh();
  context.read<BadgeController>().refresh();
  context.read<AuthController>().refreshMe();
}
