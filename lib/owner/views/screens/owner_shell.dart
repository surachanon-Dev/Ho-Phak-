import 'package:flutter/material.dart';

import '../../controller/owner_controller.dart';
import '../widgets/floating_nav.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

/// โครงหลังล็อกอิน: สลับหน้าหลักกับโปรไฟล์ มีแถบนำทางลอยด้านล่าง
class OwnerShell extends StatefulWidget {
  const OwnerShell({super.key});

  @override
  State<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends State<OwnerShell> {
  final _dashboard = GlobalKey<DashboardScreenState>();
  int _tab = 0;

  Future<void> _logout() async {
    await OwnerController.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _addDormitory() {
    setState(() => _tab = 0);
    _dashboard.currentState?.openForm();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _tab,
            children: [
              DashboardScreen(key: _dashboard, onOpenProfile: () => setState(() => _tab = 1)),
              ProfileScreen(onLogout: _logout),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Center(
                  child: FloatingNav(index: _tab, onSelect: (i) => setState(() => _tab = i), onAdd: _addDormitory),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
