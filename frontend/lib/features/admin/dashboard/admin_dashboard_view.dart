import 'package:flutter/material.dart';

import '../../../core/utils/responsive.dart';

/// หน้า 02 · DASHBOARD (A-1 และ A-1b)
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
  });

  final bool allCaughtUp;
  final int dormsAwaitingCount;
  final int reportedReviewsCount;
  final int suspendedCount;
  final int suspendedDorms;
  final int suspendedAccounts;
  final int totalWaiting;
  final ValueChanged<int> onSelectMenu;
  final List<ActivityRowData> activities;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isWideLayout(context) ? 28 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Good morning, Admin',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            allCaughtUp
                ? 'Nothing is waiting for you right now.'
                : '$totalWaiting items are waiting for your review.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 18),
          StackOnNarrow(
            row: Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.apartment_outlined,
                    count: dormsAwaitingCount,
                    title: 'Dorms awaiting review',
                    subtitle: allCaughtUp
                        ? 'Nothing waiting'
                        : '3 new · 2 changes',
                    onTap: () => onSelectMenu(3),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.error_outline,
                    count: reportedReviewsCount,
                    title: 'Reported reviews',
                    subtitle: allCaughtUp
                        ? 'Nothing waiting'
                        : 'Reported by owners',
                    onTap: () => onSelectMenu(5),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.block,
                    count: suspendedCount,
                    title: 'Suspended',
                    subtitle: allCaughtUp
                        ? 'Nothing waiting'
                        : '$suspendedDorms ${suspendedDorms == 1 ? 'dorm' : 'dorms'} · '
                              '$suspendedAccounts ${suspendedAccounts == 1 ? 'account' : 'accounts'}',
                    onTap: () => onSelectMenu(3),
                  ),
                ),
              ],
            ),
          ),
          if (allCaughtUp) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.check,
                      size: 20,
                      color: Color(0xFF15803D),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'All caught up',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'New dorms and reviews will show up here.',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Recent activity',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    InkWell(
                      onTap: () => onSelectMenu(5),
                      child: const Text(
                        'View all',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0062D6),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (isWideLayout(context))
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(7),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'TIME',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'ADMIN',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'ACTION',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Text(
                                  'TARGET',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        for (int i = 0; i < activities.length; i++) ...[
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    activities[i].time,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    activities[i].admin,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: activities[i].pillBg,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        activities[i].action,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: activities[i].pillText,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    activities[i].target,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                if (!isWideLayout(context)) _activityCards(activities),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// กิจกรรมล่าสุดแบบการ์ดสำหรับจอแคบ
Widget _activityCards(List<ActivityRowData> rows) {
  if (rows.isEmpty) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'No recent activity',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      ),
    );
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final r in rows)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.time,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${r.admin} · ${r.target}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: r.pillBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  r.action,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: r.pillText,
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.count,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final int count;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F1FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 17, color: const Color(0xFF0062D6)),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
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
    required this.pillBg,
    required this.pillText,
  });

  final String time;
  final String admin;
  final String action;
  final String target;
  final Color pillBg;
  final Color pillText;

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
      pillBg: approving
          ? const Color(0xFFDCFCE7)
          : negative
          ? const Color(0xFFFEE2E2)
          : const Color(0xFFE2E8F0),
      pillText: approving
          ? const Color(0xFF15803D)
          : negative
          ? const Color(0xFFB91C1C)
          : const Color(0xFF475569),
    );
  }
}
