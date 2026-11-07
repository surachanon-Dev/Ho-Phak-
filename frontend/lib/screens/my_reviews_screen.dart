import 'package:flutter/material.dart';

import '../models/dormitory.dart';
import '../models/review.dart';
import '../services/app_services.dart';
import '../ui/app_theme.dart';
import '../ui/error_handling.dart';

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
      if (!mounted) return;
      setState(() {
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

  @override
  Widget build(BuildContext context) {
    final avg = _avg;
    return Scaffold(
      appBar: AppBar(title: const Text('รีวิวของฉัน')),
      body: _loading && _all.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(
                          avg == null ? '-' : avg.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${_visible.length} รีวิว'
                            '${_filter == null ? ' จาก ${_dormNames.length} หอพัก' : ''}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('ทั้งหมด'),
                      selected: _filter == null,
                      onSelected: (_) => setState(() => _filter = null),
                    ),
                    for (final name in _dormNames)
                      ChoiceChip(
                        label: Text(name),
                        selected: _filter == name,
                        onSelected: (_) => setState(() => _filter = name),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_visible.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: Center(child: Text('ยังไม่มีรีวิวที่เผยแพร่')),
                  )
                else
                  ..._visible.map(
                    (e) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.dormName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '★' * e.review.rating,
                              style: const TextStyle(
                                color: AppColors.warningText,
                              ),
                            ),
                            if (e.review.body != null &&
                                e.review.body!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(e.review.body!),
                              ),
                            const SizedBox(height: 6),
                            Text(
                              e.review.createdAt,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                const Text(
                  'เจ้าของตอบกลับรีวิวไม่ได้',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
    );
  }
}
