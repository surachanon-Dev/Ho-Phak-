import 'package:flutter/material.dart';

import '../../services/app_services.dart';
import 'admin_logs_tab.dart';
import 'admin_moderation_tab.dart';
import 'admin_queue_tab.dart';
import 'admin_reviews_tab.dart';

/// โครงหลักของแอดมิน: คิวตรวจ / รีวิว / ระงับ / ประวัติ
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final s = widget.services;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          AdminQueueTab(services: s),
          AdminReviewsTab(services: s),
          AdminModerationTab(services: s),
          AdminLogsTab(services: s),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'คิวตรวจ',
          ),
          NavigationDestination(
            icon: Icon(Icons.rate_review_outlined),
            selectedIcon: Icon(Icons.rate_review),
            label: 'รีวิว',
          ),
          NavigationDestination(
            icon: Icon(Icons.block_outlined),
            selectedIcon: Icon(Icons.block),
            label: 'ระงับ',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'ประวัติ',
          ),
        ],
      ),
    );
  }
}
