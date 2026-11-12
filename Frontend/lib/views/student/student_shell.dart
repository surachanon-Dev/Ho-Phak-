import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/badge_controller.dart';
import '../../controllers/favorites_controller.dart';
import '../common/profile_view.dart';
import '../widgets/top_actions.dart';
import 'favorites_view.dart';
import 'home_view.dart';
import 'map_view.dart';
import 'search_view.dart';

/// Student area – 5 tabs (as in the UI design) + chat & bell in the app bar
class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _index = 0;
  final _searchKey = GlobalKey<SearchViewState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesController>().load();
      context.read<BadgeController>().refresh();
    });
  }

  void _openSearch({String? zone, String? sort}) {
    setState(() => _index = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) => _searchKey.currentState?.applyQuick(zone: zone, sort: sort));
  }

  static const _titles = ['Ho-Phak', 'ค้นหาหอพัก', 'แผนที่', 'รายการโปรด', 'โปรไฟล์'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index]), actions: topActions(context)),
      body: IndexedStack(index: _index, children: [
        HomeView(onOpenSearch: _openSearch),
        SearchView(key: _searchKey),
        const DormMapView(),
        const FavoritesView(),
        const ProfileView(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'หน้าหลัก'),
          NavigationDestination(icon: Icon(Icons.search), label: 'ค้นหา'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'แผนที่'),
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'รายการโปรด'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'โปรไฟล์'),
        ],
      ),
    );
  }
}
