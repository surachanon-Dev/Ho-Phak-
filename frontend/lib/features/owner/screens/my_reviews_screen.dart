import 'package:flutter/material.dart';

import '../../../core/app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../app/session.dart';
import '../../../shared/widgets/ui/ui.dart';
import '../widgets/owner_ui.dart';
import '../../../core/utils/format.dart';
import '../models/owner_reviews_bundle.dart';
import '../controllers/my_reviews_controller.dart';

/// รีวิวของหอพักทั้งหมดของเจ้าของ (อ่านอย่างเดียว) พร้อมตัวกรองตามหอพัก
class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  late final MyReviewsController _c;

  @override
  void initState() {
    super.initState();
    _c = MyReviewsController(widget.services.dormitories);
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

  /// Report รีวิว (Figma O-12e): ต้องใส่เหตุผล ไม่เกิน 300 ตัวอักษร
  Future<void> _report(OwnerReviewEntry e) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _ReportDialog(entry: e),
    );
    if (reason == null) return;
    final ok = await _c.report(e.review.id, reason);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report sent. Admin will check it.')),
      );
    } else if (_c.error != null) {
      showApiError(context, widget.services, _c.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avg = _c.average;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My reviews'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: _c.showFullLoader
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                OwnerBody(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ---- สรุปคะแนน (ตัวเลขใหญ่ + ดาว + จำนวนรีวิว) ----
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                        ),
                        child: Row(
                          children: [
                            Text(
                              avg == null ? '-' : avg.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _Stars(
                                    rating: avg?.round() ?? 0,
                                    size: 20,
                                    emptyColor: const Color(0x55FFFFFF),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${_c.visible.length} ${_c.visible.length == 1 ? 'review' : 'reviews'}'
                                    '${_c.filter == null ? ' across ${_c.dormNames.length} ${_c.dormNames.length == 1 ? 'dorm' : 'dorms'}' : ''}',
                                    style: const TextStyle(
                                      color: Color(0xE6FFFFFF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // ---- ตัวกรองตามหอ ----
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'All',
                              selected: _c.filter == null,
                              onTap: () => _c.setFilter(null),
                            ),
                            for (final name in _c.dormNames) ...[
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: name,
                                selected: _c.filter == name,
                                onTap: () => _c.setFilter(name),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_c.visible.isEmpty)
                        const EmptyState(
                          icon: Icons.rate_review_outlined,
                          tone: Tone.neutral,
                          title: 'No published reviews yet',
                          message: 'Reviews from students will appear here once published.',
                        )
                      else
                        for (final e in _c.visible) ...[
                          _ReviewCard(
                            entry: e,
                            reported: _c.isReported(e.review.id),
                            onReport: () => _report(e),
                          ),
                          const SizedBox(height: 10),
                        ],
                      const SizedBox(height: 6),
                      const Text(
                        'Owners cannot reply to reviews. You can report one that breaks the rules.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
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

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.entry,
    required this.reported,
    required this.onReport,
  });

  final OwnerReviewEntry entry;
  final bool reported;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final r = entry.review;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(icon: Icons.apartment_rounded, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.dormName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _Stars(rating: r.rating, size: 15),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                relativeDay(r.createdAt),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          if (r.body != null && r.body!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                r.body!,
                style: const TextStyle(color: AppColors.textBody, height: 1.5),
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: reported
                ? const Padding(
                    padding: EdgeInsets.only(top: 10, bottom: 4),
                    child: ToneBadge(
                      label: 'Reported · waiting for admin',
                      tone: Tone.warning,
                      icon: Icons.flag_outlined,
                    ),
                  )
                : TextButton.icon(
                    onPressed: onReport,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
                    ),
                    icon: const Icon(Icons.flag_outlined, size: 17),
                    label: const Text(
                      'Report',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// ดาว 5 ดวง: ดวงที่ได้เป็นสีส้ม ที่เหลือเป็นสีเทา
class _Stars extends StatelessWidget {
  const _Stars({
    required this.rating,
    required this.size,
    this.emptyColor = AppColors.border,
  });

  final int rating;
  final double size;
  final Color emptyColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            Icons.star_rounded,
            size: size,
            color: i <= rating ? const Color(0xFFF59E0B) : emptyColor,
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
              color: selected ? Colors.white : AppColors.textBody,
            ),
          ),
        ),
      ),
    );
  }
}

/// กล่อง Report this review?
class _ReportDialog extends StatefulWidget {
  const _ReportDialog({required this.entry});

  final OwnerReviewEntry entry;

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
      icon: const IconBadge(
        icon: Icons.flag_outlined,
        tone: Tone.danger,
        size: 48,
      ),
      title: const Text('Report this review?', textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin will check it. The review stays visible until admin decides.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.entry.dormName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
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
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: valid
              ? () => Navigator.of(context).pop(_reason.text.trim())
              : null,
          child: const Text('Send report'),
        ),
      ],
    );
  }
}
