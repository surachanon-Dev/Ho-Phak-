import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/activity.dart';
import '../../services/owner_service.dart';
import '../widgets/common.dart';

/// Owner: published reviews of my dorms (read-only – moderation is the admin's job)
class OwnerReviewsView extends StatefulWidget {
  const OwnerReviewsView({super.key});

  @override
  State<OwnerReviewsView> createState() => _OwnerReviewsViewState();
}

class _OwnerReviewsViewState extends State<OwnerReviewsView> {
  late Future<List<Review>> _future = context.read<OwnerService>().reviewsOfMyDorms();

  Future<void> _reload() async {
    final f = context.read<OwnerService>().reviewsOfMyDorms();
    setState(() => _future = f);
    await f;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snap.hasError) return ErrorRetry(message: snap.error.toString(), onRetry: _reload);
        final list = snap.data!;
        if (list.isEmpty) return const EmptyState(icon: Icons.rate_review_outlined, message: 'ยังไม่มีรีวิวที่เผยแพร่');
        final avg = list.fold<int>(0, (n, r) => n + r.rating) / list.length;
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.star_rounded, color: Colors.amber, size: 36),
                title: Text('คะแนนเฉลี่ย ${avg.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('จาก ${list.length} รีวิว'),
              ),
            ),
            const SizedBox(height: 8),
            for (final r in list)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.dormName ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
                    Row(children: [Text(r.userName ?? '-'), const Spacer(), Stars(r.rating)]),
                    if ((r.body ?? '').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(r.body!)),
                    Text(formatDate(r.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  ]),
                ),
              ),
          ]),
        );
      },
    );
  }
}
