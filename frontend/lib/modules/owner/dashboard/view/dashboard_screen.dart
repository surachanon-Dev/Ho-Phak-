import 'package:flutter/material.dart';

import '../../../../model/dormitory.dart';
import '../controller/owner_dashboard_controller.dart';
import '../../../../core/app_services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../app/session.dart';
import '../../../../core/utils/status_style.dart';
import '../../dorm_detail/view/dormitory_detail_screen.dart';
import '../../dorm_form/view/dormitory_form_screen.dart';
import '../../../../widgets/ui/ui.dart';
import '../../widgets/owner_ui.dart';

/// หน้า My Dorms ของเจ้าของ: สรุปจำนวน, แบนเนอร์หอที่ต้องดู และรายการหอ
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final OwnerDashboardController _c;

  @override
  void initState() {
    super.initState();
    _c = OwnerDashboardController(widget.services.dormitories);
    _c.addListener(() {
      if (mounted) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final ok = await _c.load();
    if (!ok && mounted && _c.error != null) {
      showApiError(context, widget.services, _c.error!);
    }
  }

  Future<void> _openForm() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DormitoryFormScreen(services: widget.services),
      ),
    );
    if (changed == true) _load();
  }

  Future<void> _openDetail(Dormitory dorm) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DormitoryDetailScreen(
          services: widget.services,
          dormitoryId: dorm.id,
        ),
      ),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final summary = _c.summary;
    final attentionTotal = summary.attentionTotal;
    final wide = MediaQuery.sizeOf(context).width >= 720;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _c.showFullLoader
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  children: [
                    OwnerBody(
                      maxWidth: 1040,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Header(
                            count: _c.items.length,
                            totalAvailable: summary.totalAvailable,
                            published: summary.published,
                            onAdd: _openForm,
                          ),
                          const SizedBox(height: 16),
                          if (attentionTotal > 0) ...[
                            _AttentionBanner(
                              total: attentionTotal,
                              counts: summary.attention,
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_c.items.isEmpty)
                            _EmptyState(onAdd: _openForm)
                          else ...[
                            SectionTitle(
                              'Your dorms',
                              subtitle: 'Tap a dorm to manage rooms, photos and reviews',
                              trailing: Text(
                                '${_c.items.length}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (wide)
                              LayoutBuilder(
                                builder: (context, c) {
                                  const gap = 14.0;
                                  final w = (c.maxWidth - gap) / 2;
                                  return Wrap(
                                    spacing: gap,
                                    runSpacing: gap,
                                    children: [
                                      for (final dorm in _c.items)
                                        SizedBox(
                                          width: w,
                                          child: _DormCard(
                                            dorm: dorm,
                                            onTap: () => _openDetail(dorm),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              )
                            else
                              for (final dorm in _c.items) ...[
                                _DormCard(
                                  dorm: dorm,
                                  onTap: () => _openDetail(dorm),
                                ),
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

/// ใส่เครื่องหมายจุลภาคคั่นหลักพัน เช่น 3200 → 3,200
String formatBaht(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

/// หัวหน้าไล่สี: ชื่อหน้า ปุ่มเพิ่มหอ และตัวเลขสรุป 3 ช่อง
class _Header extends StatelessWidget {
  const _Header({
    required this.count,
    required this.totalAvailable,
    required this.published,
    required this.onAdd,
  });

  final int count;
  final int totalAvailable;
  final int published;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: const [
          BoxShadow(
            color: Color(0x334F46E5),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Dorms',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Manage your listings in one place',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Color(0xD9FFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryDark,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add dorm'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // แสดงการ์ดสถิติเสมอ (ยังไม่มีหอ = 0 ทั้งหมด)
          Row(
            children: [
              _HeaderStat(
                icon: Icons.apartment_rounded,
                label: 'Total dorms',
                value: '$count',
              ),
              const SizedBox(width: 10),
              _HeaderStat(
                icon: Icons.meeting_room_outlined,
                label: 'Available rooms',
                value: '$totalAvailable',
              ),
              const SizedBox(width: 10),
              _HeaderStat(
                icon: Icons.public_rounded,
                label: 'Published',
                value: '$published',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x24FFFFFF),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: const Color(0xCCFFFFFF)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            // ป้ายต้องอยู่บรรทัดเดียวเสมอ → ย่อลงถ้าที่ไม่พอ
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                style: const TextStyle(fontSize: 12, color: Color(0xD9FFFFFF)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DormCard extends StatelessWidget {
  const _DormCard({required this.dorm, required this.onTap});

  final Dormitory dorm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cover = dorm.coverUrl; // รูปแรกใน images หรือ cover_image จากรายการ
    final hasRooms = dorm.availableRooms > 0;
    final ratio = dorm.totalRooms == 0
        ? 0.0
        : (dorm.availableRooms / dorm.totalRooms).clamp(0.0, 1.0);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          DormCover(url: cover, width: 92, height: 92),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        dorm.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    StatusChip(displayStatus: dorm.status),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 14,
                      color: AppColors.textFaint,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        '${zoneLabel(dorm.zone)} · ${formatBaht(dorm.pricePerMonth)} THB/month',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 5,
                    backgroundColor: const Color(0xFFEDEFF5),
                    color: hasRooms ? AppColors.success : AppColors.textFaint,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${dorm.availableRooms} of ${dorm.totalRooms} rooms available',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: hasRooms ? AppColors.success : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttentionBanner extends StatelessWidget {
  const _AttentionBanner({required this.total, required this.counts});

  final int total;
  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final detail = counts.entries
        .map((e) => '${e.value} ${DormStatus.label(e.key).toLowerCase()}')
        .join(' · ');
    return NoticeBanner(
      tone: Tone.warning,
      icon: Icons.priority_high_rounded,
      title: total == 1
          ? '1 dorm needs your attention'
          : '$total dorms need your attention',
      message: detail,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: EmptyState(
        icon: Icons.add_home_work_outlined,
        title: 'Add your first dorm',
        message: 'Admin reviews every dorm before students can see it (usually 1–2 days).',
        action: FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Add dorm'),
        ),
      ),
    );
  }
}
