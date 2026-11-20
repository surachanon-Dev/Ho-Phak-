import 'package:flutter/material.dart';

import '../../../../app/session.dart';
import '../../../../core/app_services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../model/review.dart';
import '../../../../widgets/ui/ui.dart';
import '../controller/my_reviews_controller.dart';
import '../../widgets/student_ui.dart';
import '../../dorm_detail/view/review_form_screen.dart';
import '../../dorm_detail/view/student_dorm_detail_screen.dart';

/// รีวิวของฉัน: ดูสถานะ (รอตรวจ / เผยแพร่ / ถูกซ่อน) แก้ไข และลบ
class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({
    super.key,
    required this.services,
    required this.myUserId,
  });

  final AppServices services;
  final int myUserId;

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  late final MyReviewsController _c;

  @override
  void initState() {
    super.initState();
    _c = MyReviewsController(widget.services.publicDorms);
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

  void _snack(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _edit(MyReview r) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ReviewFormScreen(
          dormName: r.dormitoryName,
          initialRating: r.rating,
          initialBody: r.body,
          isHidden: r.isHidden,
          onSubmit: (rating, body) async {
            final ok = await _c.update(r.id, rating: rating, body: body);
            if (!ok && mounted && _c.error != null) {
              showApiError(context, widget.services, _c.error!);
            }
            return ok;
          },
        ),
      ),
    );
    if (saved == true && mounted) {
      _snack('Review updated.');
    }
  }

  Future<void> _delete(MyReview r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this review?'),
        content: Text(
          'Your review of "${r.dormitoryName}" will be removed. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final removed = await _c.remove(r.id);
    if (!mounted) return;
    if (removed) {
      _snack('Review deleted');
    } else if (_c.error != null) {
      showApiError(context, widget.services, _c.error!);
    }
  }

  void _openDorm(MyReview r) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => StudentDormDetailScreen(
        services: widget.services,
        dormitoryId: r.dormitoryId,
        myUserId: widget.myUserId,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My reviews')),
      body: RefreshIndicator(
        onRefresh: _c.load,
        child: _c.showFullLoader
            ? const Center(child: CircularProgressIndicator())
            : _c.items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 60),
                  if (_c.error != null)
                    ErrorState(message: _c.error.toString(), onRetry: _c.load)
                  else
                    const EmptyState(
                      icon: Icons.rate_review_outlined,
                      title: 'No reviews yet',
                      message: 'Open a dorm and tap "Write a review" to share your experience.',
                    ),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  StudentBody(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final r in _c.items) ...[
                          _ReviewCard(
                            review: r,
                            onOpen: () => _openDorm(r),
                            onEdit: () => _edit(r),
                            onDelete: () => _delete(r),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final MyReview review;
  final VoidCallback? onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final r = review;
    final (label, tone, icon) = switch (r.status) {
      'hidden' => (
        'Hidden by admin',
        Tone.danger,
        Icons.visibility_off_outlined,
      ),
      // รีวิวขึ้นทันที จึงมีแค่ published กับ hidden (ค่าอื่นถือว่าแสดงอยู่)
      _ => ('Published', Tone.success, Icons.check_circle_outline),
    };
    return AppCard(
      onTap: onOpen,
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.dormitoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Review options',
                onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Stars(r.rating),
              const SizedBox(width: 8),
              Text(
                formatDate(r.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          if ((r.body ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              r.body!,
              style: const TextStyle(color: AppColors.textBody, height: 1.45),
            ),
          ],
          const SizedBox(height: 10),
          ToneBadge(label: label, tone: tone, icon: icon),
          if (r.isHidden && (r.moderationReason ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: NoticeBanner(
                tone: Tone.danger,
                title: 'Reason from admin',
                message: r.moderationReason!,
              ),
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
