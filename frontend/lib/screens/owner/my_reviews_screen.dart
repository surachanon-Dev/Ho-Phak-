import 'package:flutter/material.dart';

import '../../models/dormitory.dart';
import '../../models/review.dart';
import '../../services/app_services.dart';
import '../../services/owner_extras.dart';
import '../../ui/app_theme.dart';
import '../../ui/error_handling.dart';
import '../../ui/format.dart';

/// รีวิวของหอพักทั้งหมดของเจ้าของ (อ่านอย่างเดียว) พร้อมตัวกรองตามหอพัก
class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _ReviewEntry {
  _ReviewEntry(this.dormName, this.review);
  final String dormName;
  final OwnerReview review;
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  List<_ReviewEntry> _all = [];
  List<String> _dormNames = [];
  Map<int, ReviewReport> _reports = {};
  String? _filter;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// รวมรีวิวจากทุกหอพักของเจ้าของ (GET reviews ต่อหอ)
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dorms = await widget.services.dormitories.list();
      final entries = <_ReviewEntry>[];
      for (final Dormitory d in dorms) {
        final reviews = await widget.services.dormitories.reviews(d.id);
        entries.addAll(reviews.map((r) => _ReviewEntry(d.name, r)));
      }
      final reports = await widget.services.extras.reports();
      if (!mounted) return;
      setState(() {
        _reports = reports;
        _all = entries;
        _dormNames = dorms.map((d) => d.name).toList();
      });
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<_ReviewEntry> get _visible => _filter == null
      ? _all
      : _all.where((e) => e.dormName == _filter).toList();

  double? get _avg {
    final list = _visible;
    if (list.isEmpty) return null;
    return list.fold<int>(0, (s, e) => s + e.review.rating) / list.length;
  }

  /// Report รีวิว (Figma O-12e): ต้องใส่เหตุผล ไม่เกิน 300 ตัวอักษร
  Future<void> _report(_ReviewEntry e) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _ReportDialog(entry: e),
    );
    if (reason == null) return;
    try {
      await widget.services.extras.reportReview(e.review.id, reason);
      final reports = await widget.services.extras.reports();
      if (!mounted) return;
      setState(() => _reports = reports);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report sent. Admin will check it.')),
      );
    } catch (err) {
      if (mounted) showApiError(context, widget.services, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avg = _avg;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My reviews'),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: _loading && _all.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ---- สรุปคะแนน (ตัวเลขใหญ่ + ดาว + จำนวนรีวิว) ----
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(
                          avg == null ? '-' : avg.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Stars(rating: avg?.round() ?? 0, size: 18),
                              const SizedBox(height: 4),
                              Text(
                                '${_visible.length} ${_visible.length == 1 ? 'review' : 'reviews'}'
                                '${_filter == null ? ' across ${_dormNames.length} ${_dormNames.length == 1 ? 'dorm' : 'dorms'}' : ''}',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // ---- ตัวกรองตามหอ: ชิปทรงแคปซูล (เลือก = น้ำเงินตัวขาว) ----
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _filter == null,
                        onTap: () => setState(() => _filter = null),
                      ),
                      for (final name in _dormNames) ...[
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: name,
                          selected: _filter == name,
                          onTap: () => setState(() => _filter = name),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_visible.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: Center(child: Text('No published reviews yet')),
                  )
                else
                  ..._visible.map(
                    (e) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    e.dormName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  relativeDay(e.review.createdAt),
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            _Stars(rating: e.review.rating, size: 16),
                            if (e.review.body != null &&
                                e.review.body!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  e.review.body!,
                                  style: const TextStyle(
                                    color: Color(0xFF374151),
                                  ),
                                ),
                              ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: _reports.containsKey(e.review.id)
                                  ? Container(
                                      margin: const EdgeInsets.only(top: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.warningBg,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: const Text(
                                        'Reported · waiting for admin',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.warningText,
                                        ),
                                      ),
                                    )
                                  : TextButton(
                                      onPressed: () => _report(e),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.danger,
                                        padding: const EdgeInsets.only(
                                          top: 4,
                                        ),
                                        minimumSize: const Size(0, 28),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Report',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: const Text(
                    'Owners cannot reply to reviews. You can report one that breaks the rules.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
              ],
            ),
    );
  }
}

/// ดาว 5 ดวง: ดวงที่ได้เป็นสีส้ม ที่เหลือเป็นสีเทา (ตาม Figma O-12)
class _Stars extends StatelessWidget {
  const _Stars({required this.rating, required this.size});

  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            Icons.star,
            size: size,
            color: i <= rating
                ? const Color(0xFFF5A623)
                : const Color(0xFFD9DCE3),
          ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF111827),
            ),
          ),
        ),
      ),
    );
  }
}


/// กล่อง Report this review? (Figma O-12e)
class _ReportDialog extends StatefulWidget {
  const _ReportDialog({required this.entry});

  final _ReviewEntry entry;

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.entry.review;
    final valid = _reason.text.trim().isNotEmpty;
    return AlertDialog(
      title: const Text('Report this review?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin will check it. The review stays visible until admin decides.',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.entry.dormName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _Stars(rating: r.rating, size: 13),
                    ],
                  ),
                  if (r.body != null && r.body!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(r.body!),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Reason (required)',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _reason,
              maxLines: 3,
              maxLength: 300,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Why is this review wrong or against the rules?',
              ),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: valid
              ? () => Navigator.of(context).pop(_reason.text.trim())
              : null,
          child: const Text('Send report'),
        ),
      ],
    );
  }
}
