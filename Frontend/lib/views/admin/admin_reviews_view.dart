import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/activity.dart';
import '../../services/admin_service.dart';
import '../widgets/common.dart';
import 'admin_common.dart';

/// Admin: view all reviews (read-only – no publish / hide)
class AdminReviewsView extends StatefulWidget {
  const AdminReviewsView({super.key});

  @override
  State<AdminReviewsView> createState() => _AdminReviewsViewState();
}

class _AdminReviewsViewState extends State<AdminReviewsView> {
  String _q = '';
  late Future<List<Review>> _future = _fetch();

  Future<List<Review>> _fetch() => context.read<AdminService>().reviews(q: _q);
  void _reload() => setState(() => _future = _fetch());

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: TextField(
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ค้นหาชื่อหอพัก ผู้รีวิว หรือข้อความ'),
          onSubmitted: (v) {
            _q = v;
            _reload();
          },
        ),
      ),
      Expanded(
        child: AsyncList<Review>(
          future: _future,
          onRetry: _reload,
          emptyText: 'ยังไม่มีรีวิว',
          emptyIcon: Icons.rate_review_outlined,
          builder: (list) => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              if (i == 0) {
                return Text('ทั้งหมด ${list.length} รีวิว', style: const TextStyle(color: AppColors.muted));
              }
              final r = list[i - 1];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.dormName ?? 'หอพัก #${r.dormitoryId}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
                    Row(children: [Text('โดย ${r.userName ?? '-'}'), const Spacer(), Stars(r.rating)]),
                    if ((r.body ?? '').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(r.body!)),
                    Text(formatDateTime(r.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  ]),
                ),
              );
            },
          ),
        ),
      ),
    ]);
  }
}
