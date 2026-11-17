import 'package:flutter/material.dart';

import '../controllers/student_home_controller.dart';
import '../../../shared/models/dormitory.dart';
import '../../../shared/models/user.dart';
import '../../../core/app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/dorm_card.dart';
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
  late final StudentHomeController _c;

  @override
  void initState() {
    super.initState();
    _c = StudentHomeController(widget.services.publicDorms);
    _c.addListener(_onChanged);
    _c.load();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _c.removeListener(_onChanged);
    _c.dispose();
    super.dispose();
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
        onRefresh: _c.refresh,
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
            if (_c.showFullLoader)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_c.error != null)
              _ErrorState(message: _c.error.toString(), onRetry: _c.load)
            else if (_c.isEmpty)
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
                  for (final d in _c.items)
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
