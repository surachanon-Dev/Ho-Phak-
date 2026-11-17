import 'package:flutter/material.dart';

import 'package:hopak_frontend/features/student/home/student_home_controller.dart';
import 'package:hopak_frontend/features/student/search/dorm_search_controller.dart';
import 'package:hopak_frontend/features/student/widgets/student_widgets.dart';
import 'package:hopak_frontend/shared/models/dormitory.dart';
import 'package:hopak_frontend/shared/models/user.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/core/theme/app_theme.dart';
import 'package:hopak_frontend/core/utils/format.dart';
import 'package:hopak_frontend/shared/widgets/dorm_card.dart';
import 'package:hopak_frontend/features/student/search/search_screen.dart';
import 'package:hopak_frontend/features/student/dorm_detail/student_dorm_detail_screen.dart';

/// เปิดหน้าค้นหาพร้อมตัวกรองเริ่มต้น (โซน / การเรียง)
typedef OpenSearch = void Function({String? zone, String? sort});

/// หน้าแรกนักศึกษา (หน้าตาตาม Frontend-Big): ทักทาย, ช่องค้นหา, ชิปโซน,
/// หอพักแนะนำ (คะแนนสูง) และหอพักใกล้มหาวิทยาลัย
class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({
    super.key,
    required this.services,
    required this.user,
    this.onOpenSearch,
    this.actions,
  });

  final AppServices services;
  final CurrentUser user;

  /// ให้ StudentShell สลับไปแท็บค้นหา ถ้าไม่ส่งมาจะเปิดหน้าค้นหาใหม่แทน
  final OpenSearch? onOpenSearch;

  /// ปุ่มบน app bar (แชท / แจ้งเตือน)
  final List<Widget>? actions;

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

  void _openSearch({String? zone, String? sort}) {
    final open = widget.onOpenSearch;
    if (open != null) return open(zone: zone, sort: sort);
    final key = GlobalKey<SearchScreenState>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchScreen(
          key: key,
          services: widget.services,
          myUserId: widget.user.id,
        ),
      ),
    );
    if (zone != null || sort != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => key.currentState?.applyQuick(zone: zone, sort: sort),
      );
    }
  }

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
    // หอแนะนำ = เฉพาะหอที่มีรีวิวแล้ว เรียงคะแนนสูงสุด 5 อันดับ
    final top = sortLocally(
      _c.items.where((d) => d.ratingAvg != null).toList(),
      'rating',
    ).take(5).toList();
    final near = sortLocally(_c.items, 'distance').take(5).toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Ho-Phak'),
        actions: widget.actions,
      ),
      body: RefreshIndicator(
        onRefresh: _c.refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'สวัสดี, ${widget.user.username ?? 'นักศึกษา'}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const Text(
              'กำลังมองหาหอพักที่ใช่อยู่ใช่ไหม?',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _openSearch,
              borderRadius: BorderRadius.circular(10),
              child: const IgnorePointer(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ค้นหาชื่อหอพัก...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
            ),
            const SectionTitle('โซน'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final z in dormZones)
                  ActionChip(
                    avatar: const Icon(
                      Icons.place,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    label: Text(z),
                    onPressed: () => _openSearch(zone: z),
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
            else ...[
              if (top.isNotEmpty) ...[
                SectionTitle(
                  'หอพักแนะนำ (คะแนนสูง)',
                  trailing: TextButton(
                    onPressed: () => _openSearch(sort: 'rating'),
                    child: const Text('ดูทั้งหมด'),
                  ),
                ),
                SizedBox(
                  height: 214,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: top.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => _TopDormCard(
                      dorm: top[i],
                      onTap: () => _openDetail(top[i]),
                    ),
                  ),
                ),
              ],
              SectionTitle(
                'ใกล้มหาวิทยาลัยแม่ฟ้าหลวง',
                trailing: TextButton(
                  onPressed: () => _openSearch(sort: 'distance'),
                  child: const Text('ดูทั้งหมด'),
                ),
              ),
              for (final d in near)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DormCard(dorm: d, onTap: () => _openDetail(d)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// การ์ดแนวตั้งในแถวหอพักแนะนำ
class _TopDormCard extends StatelessWidget {
  const _TopDormCard({required this.dorm, required this.onTap});

  final Dormitory dorm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NetImage(dorm.coverUrl, height: 120, width: 220, radius: 0),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dorm.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      formatPrice(dorm.pricePerMonth),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                    RatingText(rating: dorm.ratingAvg, count: dorm.reviewCount),
                  ],
                ),
              ),
            ],
          ),
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
