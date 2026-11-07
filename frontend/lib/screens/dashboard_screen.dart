import 'package:flutter/material.dart';

import '../models/dormitory.dart';
import '../services/app_services.dart';
import '../ui/app_theme.dart';
import '../ui/error_handling.dart';
import '../ui/status_style.dart';
import 'dormitory_detail_screen.dart';
import 'dormitory_form_screen.dart';

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
    final avgPrice = _items.isEmpty
        ? 0
        : _items.fold<int>(0, (s, d) => s + d.pricePerMonth) ~/ _items.length;
    final attention = _attentionCounts();
    final attentionTotal = attention.values.fold<int>(0, (s, n) => s + n);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dorms'),
        actions: [
          IconButton(
            tooltip: 'รีเฟรช',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              onPressed: _openForm,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add dorm'),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading && _items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_items.isNotEmpty) ...[
                    Row(
                      children: [
                        _StatCard(
                          label: 'หอพักทั้งหมด',
                          value: '${_items.length}',
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          label: 'ห้องว่างรวม',
                          value: '$totalAvailable',
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          label: 'ราคาเฉลี่ย/เดือน',
                          value: '$avgPrice บาท',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (attentionTotal > 0) ...[
                    _AttentionBanner(total: attentionTotal, counts: attention),
                    const SizedBox(height: 16),
                  ],
                  if (_items.isEmpty)
                    const _EmptyState()
                  else
                    ..._items.map(
                      (dorm) =>
                          _DormCard(dorm: dorm, onTap: () => _openDetail(dorm)),
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
    final cover = dorm.images.isEmpty ? null : dorm.images.first.fullUrl;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: cover == null
                  ? const ColoredBox(
                      color: Colors.black12,
                      child: Icon(Icons.apartment_outlined),
                    )
                  : Image.network(
                      cover,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: Colors.black12,
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            dorm.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusChip(displayStatus: dorm.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dorm.zone} · ${dorm.pricePerMonth} บาท/เดือน',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ว่าง ${dorm.availableRooms} จาก ${dorm.totalRooms} ห้อง',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
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
        .map((e) => '${e.value} ${DormStatus.label(e.key)}')
        .join(' · ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$total หอพักต้องให้คุณดู',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(detail),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Text(
            'เพิ่มหอพักแรกของคุณ',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'แอดมินตรวจสอบทุกหอพักก่อนที่นักศึกษาจะเห็น มักใช้เวลา 1–2 วัน',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(value, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
