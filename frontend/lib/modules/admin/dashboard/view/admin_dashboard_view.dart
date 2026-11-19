import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../widgets/ui/ui.dart';

/// หน้า Dashboard ของแอดมิน: สรุปงานที่ค้าง + กิจกรรมล่าสุด
/// ดัชนีเมนูใน [onSelectMenu]: 1 Owner requests, 2 Dorms, 3 Users, 4 Reviews, 5 Activity log
class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({
    super.key,
    required this.allCaughtUp,
    required this.dormsAwaitingCount,
    required this.reportedReviewsCount,
    required this.suspendedCount,
    required this.suspendedDorms,
    required this.suspendedAccounts,
    required this.totalWaiting,
    required this.onSelectMenu,
    required this.activities,
    this.ownerRequestsCount = 0,
    this.loading = false,
    this.onRefresh,
  });

  final bool allCaughtUp;
  final int dormsAwaitingCount;
  final int reportedReviewsCount;
  final int suspendedCount;
  final int suspendedDorms;
  final int suspendedAccounts;
  final int totalWaiting;
  final int ownerRequestsCount;
  final ValueChanged<int> onSelectMenu;
  final List<ActivityRowData> activities;
  final bool loading;
  final Future<void> Function()? onRefresh;

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final wide = isWideLayout(context);
    final pad = wide ? 28.0 : 16.0;

    final stats = [
      StatCard(
        icon: Icons.how_to_reg_outlined,
        tone: Tone.violet,
        value: '$ownerRequestsCount',
        label: 'Owner requests',
        caption: ownerRequestsCount == 0
            ? 'Nothing waiting'
            : 'Identity checks to review',
        onTap: () => onSelectMenu(1),
      ),
      StatCard(
        icon: Icons.apartment_outlined,
        tone: Tone.primary,
        value: '$dormsAwaitingCount',
        label: 'Dorms awaiting review',
        caption: dormsAwaitingCount == 0
            ? 'Nothing waiting'
            : 'New listings and changes',
        onTap: () => onSelectMenu(2),
      ),
      StatCard(
        icon: Icons.rate_review_outlined,
        tone: Tone.warning,
        value: '$reportedReviewsCount',
        label: 'Reported reviews',
        caption: reportedReviewsCount == 0
            ? 'Nothing waiting'
            : 'Reported by owners',
        onTap: () => onSelectMenu(4),
      ),
      StatCard(
        icon: Icons.block,
        tone: Tone.danger,
        value: '$suspendedCount',
        label: 'Suspended',
        caption:
            '$suspendedDorms ${suspendedDorms == 1 ? 'dorm' : 'dorms'} · '
            '$suspendedAccounts ${suspendedAccounts == 1 ? 'account' : 'accounts'}',
        onTap: () => onSelectMenu(3),
      ),
    ];

    final body = ListView(
      padding: EdgeInsets.all(pad),
      children: [
        ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeroBanner(
                greeting: '${_greeting()}, Admin',
                message: allCaughtUp
                    ? 'Nothing is waiting for you right now.'
                    : '$totalWaiting items are waiting for your review.',
                allCaughtUp: allCaughtUp,
                loading: loading,
                onReview: allCaughtUp
                    ? null
                    : () => onSelectMenu(
                        ownerRequestsCount > 0
                            ? 1
                            : dormsAwaitingCount > 0
                            ? 2
                            : 4,
                      ),
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, c) {
                  final cols = c.maxWidth >= 900
                      ? 4
                      : c.maxWidth >= 520
                      ? 2
                      : 1;
                  const gap = 14.0;
                  final w = (c.maxWidth - gap * (cols - 1)) / cols;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final s in stats) SizedBox(width: w, child: s),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              AppCard(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionTitle(
                      'Recent activity',
                      icon: Icons.history,
                      subtitle: 'Latest moderation actions by admins',
                      trailing: TextButton(
                        onPressed: () => onSelectMenu(5),
                        child: const Text('View all'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (activities.isEmpty)
                      const EmptyState(
                        compact: true,
                        icon: Icons.inbox_outlined,
                        tone: Tone.neutral,
                        title: 'No recent activity',
                        message: 'Actions you take will appear here.',
                      )
                    else
                      for (int i = 0; i < activities.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        _ActivityTile(row: activities[i], wide: wide),
                      ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (onRefresh == null) return body;
    return RefreshIndicator(onRefresh: onRefresh!, child: body);
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.greeting,
    required this.message,
    required this.allCaughtUp,
    required this.loading,
    this.onReview,
  });

  final String greeting;
  final String message;
  final bool allCaughtUp;
  final bool loading;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: const [
          BoxShadow(
            color: Color(0x334F46E5),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xE6FFFFFF),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                if (onReview != null) ...[
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryDark,
                      minimumSize: const Size(0, 40),
                    ),
                    onPressed: onReview,
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Start reviewing'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0x26FFFFFF),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            alignment: Alignment.center,
            child: loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    allCaughtUp
                        ? Icons.check_circle_outline
                        : Icons.pending_actions_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.row, required this.wide});

  final ActivityRowData row;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final pill = ToneBadge(label: row.action, tone: row.tone);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          IconBadge(icon: row.icon, tone: row.tone, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.target,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${row.admin} · ${row.time}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: wide ? 220 : 120),
            child: pill,
          ),
        ],
      ),
    );
  }
}

class ActivityRowData {
  const ActivityRowData({
    required this.time,
    required this.admin,
    required this.action,
    required this.target,
    this.tone = Tone.neutral,
  });

  final String time;
  final String admin;
  final String action;
  final String target;
  final Tone tone;

  Color get pillBg => tone.bg;
  Color get pillText => tone.fg;

  IconData get icon => switch (tone) {
    Tone.success => Icons.check_rounded,
    Tone.danger => Icons.remove_circle_outline,
    _ => Icons.edit_note_rounded,
  };

  /// แปลง 1 แถวจาก Activity log เป็นแถวที่ Dashboard แสดง
  factory ActivityRowData.fromLog(Map<String, dynamic> e) {
    final action = (e['action'] as String?) ?? '';
    final approving =
        action.contains('approve') ||
        action.contains('publish') ||
        action.contains('restore') ||
        action.contains('create');
    final negative =
        action.contains('reject') ||
        action.contains('hide') ||
        action.contains('suspend') ||
        action.contains('delete');
    final target = '${e['target_type'] ?? ''} #${e['target_id'] ?? ''}'.trim();
    return ActivityRowData(
      time: (e['created_at'] ?? '').toString(),
      admin: (e['admin_name'] as String?) ?? 'Admin',
      action: action,
      target: target,
      tone: approving
          ? Tone.success
          : negative
          ? Tone.danger
          : Tone.neutral,
    );
  }
}
