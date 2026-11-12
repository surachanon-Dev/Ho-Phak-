import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/activity.dart';
import '../../services/dorm_service.dart';
import '../widgets/common.dart';
import 'dorm_detail_view.dart';

/// Student: all my reviews
class MyReviewsView extends StatefulWidget {
  const MyReviewsView({super.key});

  @override
  State<MyReviewsView> createState() => _MyReviewsViewState();
}

class _MyReviewsViewState extends State<MyReviewsView> {
  late Future<List<Review>> _future = context.read<DormService>().myReviews();

  void _reload() => setState(() => _future = context.read<DormService>().myReviews());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รีวิวของฉัน')),
      body: FutureBuilder(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return ErrorRetry(message: snap.error.toString(), onRetry: _reload);
          final list = snap.data!;
          if (list.isEmpty) return const EmptyState(icon: Icons.rate_review_outlined, message: 'คุณยังไม่ได้เขียนรีวิว');
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final r = list[i];
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => DormDetailView(dormId: r.dormitoryId)));
                    _reload();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(r.dormName ?? 'หอพัก #${r.dormitoryId}', style: const TextStyle(fontWeight: FontWeight.bold))),
                      ]),
                      const SizedBox(height: 4),
                      Stars(r.rating),
                      if ((r.body ?? '').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(r.body!)),
                      Text(formatDate(r.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    ]),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
