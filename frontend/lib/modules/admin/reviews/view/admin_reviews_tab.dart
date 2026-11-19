import 'package:flutter/material.dart';

import '../controller/admin_reviews_controller.dart';
import '../../../../services/admin_service.dart';
import '../../../../core/app_services.dart';
import '../../../../app/session.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/ui/ui.dart';
import '../../owner_requests/view/widgets/owner_request_widgets.dart';
import '../../users/view/widgets/user_list_widgets.dart';
import '../../widgets/admin_page.dart';
import '../../widgets/reason_dialog.dart';

class AdminReviewsTab extends StatefulWidget {
  const AdminReviewsTab({super.key, required this.services});

  final AppServices services;

  @override
  State<AdminReviewsTab> createState() => _AdminReviewsTabState();
}

class _AdminReviewsTabState extends State<AdminReviewsTab> {
  late final AdminReviewsController _c;

  /// สถานะของแท็บตามที่หน้าจอใช้: pending | kept | hidden
  String get _currentStatus => switch (_c.status) {
    AdminReviewStatus.open => 'pending',
    AdminReviewStatus.kept => 'kept',
    AdminReviewStatus.hidden => 'hidden',
  };

  @override
  void initState() {
    super.initState();
    _c = AdminReviewsController(AdminService(widget.services.api));
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

  void _report() {
    if (!mounted) return;
    final error = _c.actionError ?? _c.loadError;
    if (error != null) showApiError(context, widget.services, error);
  }

  Future<void> _load() async {
    await _c.refresh();
    _report();
  }

  Future<void> _publish(int id) async {
    final ok = await _c.publishReview(id);
    if (!ok) _report();
  }

  Future<void> _hide(int id) async {
    final reason = await askReason(context, 'Reason for hiding the review');
    if (reason == null) return;
    final ok = await _c.hideReview(id, reason);
    if (!ok) _report();
  }

  /// กรองตามชื่อหอ (null = ทุกหอ) กรองฝั่งหน้าจอจากรายการที่โหลดมาแล้ว
  String? _dormFilter;

  @override
  Widget build(BuildContext context) {
    final dorms =
        _c.reviews
            .map((r) => r['dormitory_name']?.toString())
            .whereType<String>()
            .toSet()
            .toList()
          ..sort();
    if (_dormFilter != null && !dorms.contains(_dormFilter)) _dormFilter = null;

    final tabs = RequestTabBar(
      children: [
        for (final (i, label) in const ['Pending', 'Published', 'Hidden'].indexed)
          RequestTabButton(
            label: label,
            count: _c.status.index == i ? _c.reviews.length : null,
            selected: _c.status.index == i,
            onTap: () => _c.selectStatus(AdminReviewStatus.values[i]),
          ),
      ],
    );

    final dormPicker = FilterDropdown(
      icon: Icons.apartment_outlined,
      value: _dormFilter ?? 'All dorms',
      items: ['All dorms', ...dorms],
      onChanged: (v) =>
          setState(() => _dormFilter = v == 'All dorms' ? null : v),
    );

    return AdminPage(
      title: 'Review moderation',
      subtitle: 'Approve pending student reviews or hide inappropriate ones',
      actions: [
        HeaderIconButton(
          tooltip: 'Refresh',
          icon: Icons.refresh,
          onPressed: _c.isLoading ? null : _load,
        ),
      ],
      toolbar: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [tabs, dormPicker],
          ),
          const SizedBox(height: 12),
          _buildInfoBanner(),
        ],
      ),
      child: _buildBodyContent(),
    );
  }

  Widget _buildBodyContent() {
    if (_c.isLoading && _c.reviews.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final reviews = _dormFilter == null
        ? _c.reviews
        : _c.reviews
              .where((r) => r['dormitory_name']?.toString() == _dormFilter)
              .toList();
    if (reviews.isEmpty) {
      return const EmptyState(
        icon: Icons.reviews_outlined,
        tone: Tone.neutral,
        title: 'No reviews with this status',
        message: 'Reviews that match this tab will appear here.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: AdminListView(
        itemCount: reviews.length,
        separator: 14,
        itemBuilder: (context, i) {
          final r = reviews[i];
          return _buildReviewCard(r, r['id'] as int);
        },
      ),
    );
  }

  Widget _buildInfoBanner() {
    final text = switch (_currentStatus) {
      'pending' =>
        'New and edited student reviews wait here until an admin publishes or hides them.',
      'kept' => 'Published reviews are visible on the dorm page.',
      _ => 'Hidden reviews are removed from the dorm page.',
    };
    return NoticeBanner(tone: Tone.info, message: text);
  }

  Widget _buildReviewCard(Map<String, dynamic> r, int id) {
    final String dormName = r['dormitory_name']?.toString() ?? 'Unknown';
    final int rating = r['rating'] as int? ?? 0;
    final String body = r['body']?.toString() ?? '';
    final String author = r['author']?.toString() ?? 'Anonymous';
    final String date = r['created_at']?.toString() ?? 'posted recently';
    final String reporter = r['reporter_name']?.toString() ?? 'Owner';
    final String? reportReason = r['report_reason']?.toString().trim();
    final bool hasReport = reportReason != null && reportReason.isNotEmpty;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InitialsAvatar(name: author, size: 40, tone: Tone.info),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dormName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'by $author · $date',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _Stars(rating: rating),
                          _buildStatusBadge(),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (body.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Text(
                body,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textBody,
                ),
              ),
            ),
          if (hasReport)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: NoticeBanner(
                tone: Tone.warning,
                icon: Icons.flag_outlined,
                title: 'Reported by $reporter',
                message: '"$reportReason"',
              ),
            ),
          const SizedBox(height: 16),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  _getActionText(),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                _buildActionButtons(id),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return switch (_currentStatus) {
      'pending' => const ToneBadge(
        label: 'Pending review',
        tone: Tone.warning,
        icon: Icons.hourglass_top_rounded,
      ),
      'kept' => const ToneBadge(
        label: 'Published',
        tone: Tone.success,
        icon: Icons.check_rounded,
      ),
      _ => const ToneBadge(
        label: 'Hidden',
        tone: Tone.neutral,
        icon: Icons.visibility_off_outlined,
      ),
    };
  }

  String _getActionText() {
    if (_currentStatus == 'pending') {
      return 'Publish shows the review on the dorm page. Hide removes it.';
    } else if (_currentStatus == 'kept') {
      return 'Review is visible on the dorm page.';
    } else {
      return 'Review is removed from the dorm page.';
    }
  }

  static final _compact = OutlinedButton.styleFrom(
    minimumSize: const Size(0, 40),
    padding: const EdgeInsets.symmetric(horizontal: 14),
  );

  static final _hideStyle = FilledButton.styleFrom(
    backgroundColor: AppColors.danger,
    minimumSize: const Size(0, 40),
  );

  Widget _buildActionButtons(int id) {
    if (_currentStatus == 'pending') {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton(
            onPressed: () => _publish(id),
            style: _compact,
            child: const Text('Publish review'),
          ),
          FilledButton(
            onPressed: () => _hide(id),
            style: _hideStyle,
            child: const Text('Hide review'),
          ),
        ],
      );
    } else if (_currentStatus == 'kept') {
      return FilledButton(
        onPressed: () => _hide(id),
        style: _hideStyle,
        child: const Text('Hide review'),
      );
    } else {
      return OutlinedButton(
        onPressed: () => _publish(id),
        style: _compact,
        child: const Text('Unhide review'),
      );
    }
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 17,
            color: i <= rating
                ? const Color(0xFFF59E0B)
                : AppColors.borderStrong,
          ),
        const SizedBox(width: 6),
        Text(
          '$rating.0',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}

/// ขอเหตุผลการซ่อนรีวิว คืน null ถ้ายกเลิกหรือเว้นว่าง
Future<String?> askReason(BuildContext context, String title) async {
  final result = await showReasonDialog(
    context,
    title: title,
    message: 'Students will no longer see it. The owner is notified.',
    hint: 'Reason (required)',
    confirmLabel: 'Confirm',
    icon: Icons.visibility_off_outlined,
  );
  final text = result?.trim();
  if (text == null || text.isEmpty) return null;
  return text;
}
