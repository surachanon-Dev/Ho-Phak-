import 'package:flutter/material.dart';

import '../../models/dormitory.dart';
import '../../models/user.dart';
import '../../services/app_services.dart';
import '../../ui/app_theme.dart';
import '../../widgets/dorm_card.dart';
import 'search_screen.dart';
import 'student_dorm_detail_screen.dart';

/// หน้าแรกนักศึกษา: ช่องค้นหา และรายการหอพักที่เผยแพร่แล้ว
class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({
    super.key,
    required this.services,
    required this.user,
  });

  final AppServices services;
  final CurrentUser user;

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  List<Dormitory> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.services.publicDorms.search();
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openSearch() => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          SearchScreen(services: widget.services, myUserId: widget.user.id),
    ),
  );

  void _openDetail(Dormitory d) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => StudentDormDetailScreen(
        services: widget.services,
        dormitoryId: d.id,
        myUserId: widget.user.id,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('สวัสดี, ${widget.user.username ?? 'นักศึกษา'}'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'กำลังมองหาหอพักอยู่ใช่ไหม',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _openSearch,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: AppColors.textMuted),
                    SizedBox(width: 8),
                    Text(
                      'ค้นหาชื่อหอพัก',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ใกล้มหาวิทยาลัยแม่ฟ้าหลวง',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: _openSearch,
                  child: const Text('ดูทั้งหมด'),
                ),
              ],
            ),
            if (_loading && _items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _ErrorState(message: _error!, onRetry: _load)
            else if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 32),
                child: Center(child: Text('ยังไม่มีหอพักที่เผยแพร่')),
              )
            else
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
                children: [
                  for (final d in _items)
                    DormCard(dorm: d, onTap: () => _openDetail(d)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.wifi_off, size: 40, color: AppColors.danger),
          const SizedBox(height: 8),
          const Text('โหลดหอพักไม่ได้'),
          const SizedBox(height: 4),
          Text(
            message,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('ลองอีกครั้ง')),
        ],
      ),
    );
  }
}
