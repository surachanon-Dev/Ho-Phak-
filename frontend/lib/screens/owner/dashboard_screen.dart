import 'package:flutter/material.dart';

import '../../models/dormitory.dart';
import '../../services/app_services.dart';
import '../../ui/app_theme.dart';
import '../../ui/error_handling.dart';
import '../../ui/status_style.dart';
import 'dormitory_detail_screen.dart';
import 'dormitory_form_screen.dart';

/// หน้า My Dorms ของเจ้าของ: สรุปจำนวน, แบนเนอร์หอที่ต้องดู และรายการหอ
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Dormitory> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await widget.services.dormitories.list();
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    } finally {
      if (mounted) setState(() => _loading = false);
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

  /// นับหอพักที่ต้องให้เจ้าของดู: รอตรวจ, ไม่ผ่าน, ถูกระงับ
  Map<String, int> _attentionCounts() {
    final counts = <String, int>{};
    for (final d in _items) {
      final s = d.status;
      if (s == DormStatus.pending ||
          s == DormStatus.rejected ||
          s == DormStatus.suspended) {
        counts[s] = (counts[s] ?? 0) + 1;
      }
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final totalAvailable = _items.fold<int>(0, (s, d) => s + d.availableRooms);
    final published = _items
        .where((d) => d.status == DormStatus.published)
        .length;
    final attention = _attentionCounts();
    final attentionTotal = attention.values.fold<int>(0, (s, n) => s + n);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading && _items.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'My Dorms',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onPressed: _openForm,
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Add dorm'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // แสดงการ์ดสถิติเสมอ (หอว่าง = 0 ทั้งหมด ตามเฟรม O-1b)
                    ...[
                      Row(
                        children: [
                          _StatCard(
                            label: 'Total dorms',
                            value: '${_items.length}',
                            color: const Color(0xFF111827),
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            label: 'Available rooms',
                            value: '$totalAvailable',
                            color: const Color(0xFF1B6B33),
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            label: 'Published',
                            value: '$published',
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (attentionTotal > 0) ...[
                      _AttentionBanner(
                        total: attentionTotal,
                        counts: attention,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_items.isEmpty)
                      _EmptyState(onAdd: _openForm)
                    else
                      ..._items.map(
                        (dorm) => _DormCard(
                          dorm: dorm,
                          onTap: () => _openDetail(dorm),
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
String formatBaht(int n) => n.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => ',',
);

class _DormCard extends StatelessWidget {
  const _DormCard({required this.dorm, required this.onTap});

  final Dormitory dorm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cover = dorm.images.isEmpty ? null : dorm.images.first.fullUrl;
    final hasRooms = dorm.availableRooms > 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: cover == null
                      ? const ColoredBox(
                          color: Color(0xFFDDE2EA),
                          child: Icon(
                            Icons.apartment_outlined,
                            color: AppColors.textMuted,
                          ),
                        )
                      : Image.network(
                          cover,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const ColoredBox(
                            color: Color(0xFFDDE2EA),
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dorm.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dorm.zone} · ${formatBaht(dorm.pricePerMonth)} THB/month',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${dorm.availableRooms} of ${dorm.totalRooms} rooms available',
                      style: TextStyle(
                        fontSize: 13,
                        color: hasRooms
                            ? const Color(0xFF1B6B33)
                            : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    StatusChip(displayStatus: dorm.status),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF374151)),
            ],
          ),
        ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFFBE3A1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.priority_high,
              size: 20,
              color: AppColors.warningText,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  total == 1
                      ? '1 dorm needs your attention'
                      : '$total dorms need your attention',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: Column(
        children: [
          const Icon(
            Icons.apartment_outlined,
            size: 56,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'Add your first dorm',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Admin reviews every dorm before students can see it (usually 1–2 days).',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add dorm'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
