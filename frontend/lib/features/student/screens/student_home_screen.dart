import 'package:flutter/material.dart';

import '../../../core/app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/dormitory.dart';
import '../../../shared/models/user.dart';
import '../../../shared/widgets/dorm_card.dart';
import '../../../shared/widgets/ui/ui.dart';
import '../../owner/widgets/owner_ui.dart' show DormCover;
import '../controllers/dorm_search_controller.dart';
import '../controllers/student_home_controller.dart';
import '../widgets/student_ui.dart';
import 'search_screen.dart';
import 'student_dorm_detail_screen.dart';
import 'student_shell.dart' show StudentShortcuts;

/// เปิดหน้าค้นหาพร้อมตัวกรองเริ่มต้น (โซน / การเรียง)
typedef OpenSearch = void Function({String? zone, String? sort});

/// หน้าแรกนักศึกษา: หัวหน้าไล่สี (ทักทาย + ช่องค้นหา), ชิปโซน,
/// หอพักแนะนำ (คะแนนสูง) และหอพักใกล้มหาวิทยาลัย
class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({
    super.key,
    required this.services,
    required this.user,
    this.onOpenSearch,
    this.shortcuts,
  });

  final AppServices services;
  final CurrentUser user;

  /// ให้ StudentShell สลับไปแท็บค้นหา ถ้าไม่ส่งมาจะเปิดหน้าค้นหาใหม่แทน
  final OpenSearch? onOpenSearch;

  /// ปุ่มแชท / แจ้งเตือนบนหัวหน้า (ไม่ส่ง = ไม่แสดง)
  final StudentShortcuts? shortcuts;

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
    final shortcuts = widget.shortcuts;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _c.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              StudentBody(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StudentHero(
                      title: 'สวัสดี, ${widget.user.username ?? 'นักศึกษา'}',
                      subtitle: 'กำลังมองหาหอพักที่ใช่อยู่ใช่ไหม?',
                      trailing: shortcuts == null
                          ? null
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                HeroIconButton(
                                  icon: Icons.chat_bubble_outline_rounded,
                                  tooltip: 'ข้อความ',
                                  onPressed: shortcuts.openChats,
                                ),
                                const SizedBox(width: 6),
                                HeroIconButton(
                                  icon: Icons.notifications_none_rounded,
                                  tooltip: 'การแจ้งเตือน',
                                  onPressed: shortcuts.openNotifications,
                                ),
                              ],
                            ),
                      child: _SearchBox(onTap: () => _openSearch()),
                    ),
                    const SizedBox(height: 22),
                    const SectionTitle('โซน', icon: Icons.place_outlined),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final z in dormZones)
                          ActionChip(
                            avatar: const Icon(
                              Icons.place_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            label: Text(z),
                            onPressed: () => _openSearch(zone: z),
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    if (_c.showFullLoader)
                      const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_c.error != null)
                      EmptyState(
                        icon: Icons.cloud_off_outlined,
                        tone: Tone.danger,
                        title: 'โหลดหอพักไม่ได้',
                        message: _c.error.toString(),
                        action: FilledButton.icon(
                          onPressed: _c.load,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('ลองอีกครั้ง'),
                        ),
                      )
                    else if (_c.isEmpty)
                      const EmptyState(
                        icon: Icons.apartment_rounded,
                        title: 'ยังไม่มีหอพักที่เผยแพร่',
                        message: 'เมื่อมีหอพักผ่านการตรวจสอบ จะแสดงที่นี่',
                      )
                    else ...[
                      if (top.isNotEmpty) ...[
                        SectionTitle(
                          'หอพักแนะนำ',
                          subtitle: 'คะแนนรีวิวสูงสุด',
                          icon: Icons.star_outline_rounded,
                          trailing: TextButton(
                            onPressed: () => _openSearch(sort: 'rating'),
                            child: const Text('ดูทั้งหมด'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 226,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            itemCount: top.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (_, i) => _TopDormCard(
                              dorm: top[i],
                              onTap: () => _openDetail(top[i]),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                      ],
                      SectionTitle(
                        'ใกล้มหาวิทยาลัยแม่ฟ้าหลวง',
                        subtitle: 'เรียงตามระยะทางจากมหาวิทยาลัย',
                        icon: Icons.school_outlined,
                        trailing: TextButton(
                          onPressed: () => _openSearch(sort: 'distance'),
                          child: const Text('ดูทั้งหมด'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final d in near) ...[
                        DormCard(dorm: d, onTap: () => _openDetail(d)),
                        const SizedBox(height: 12),
                      ],
                    ],
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

/// ช่องค้นหาสีขาวบนหัวหน้า กดแล้วไปหน้าค้นหา
class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(Icons.search, size: 20, color: AppColors.textMuted),
              SizedBox(width: 10),
              Text(
                'ค้นหาชื่อหอพัก...',
                style: TextStyle(color: AppColors.textFaint),
              ),
            ],
          ),
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
      child: AppCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DormCover(url: dorm.coverUrl, width: 220, height: 120, radius: 0),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dorm.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  PriceText(dorm.pricePerMonth, size: 14),
                  const SizedBox(height: 6),
                  RatingText(rating: dorm.ratingAvg, count: dorm.reviewCount),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
