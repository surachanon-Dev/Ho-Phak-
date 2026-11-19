// ผู้รับผิดชอบ: Bank (แอดมิน)
// widget test: หน้า Dashboard ของแอดมิน
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/modules/admin/dashboard/view/admin_dashboard_view.dart';

import '../../../helpers/fake_backend.dart';

/// แถว Activity log ในรูปแบบเดียวกับ GET /api/admin/logs
final recentLogs = [
  {
    'action': 'dormitory.approve',
    'target_type': 'dormitory',
    'target_id': 8,
    'admin_name': 'admin',
    'created_at': '2026-11-17T16:03:31.000Z',
  },
  {
    'action': 'verification.approve',
    'target_type': 'verification',
    'target_id': 5,
    'admin_name': 'admin',
    'created_at': '2026-11-17T16:01:09.000Z',
  },
];

Widget dashboard({
  int ownerRequests = 0,
  int dormsWaiting = 0,
  int reviewsWaiting = 0,
  List<Map<String, dynamic>> logs = const [],
  ValueChanged<int>? onSelectMenu,
}) {
  final waiting = dormsWaiting + reviewsWaiting;
  return MaterialApp(
    home: Scaffold(
      body: AdminDashboardView(
        allCaughtUp: waiting == 0 && ownerRequests == 0,
        ownerRequestsCount: ownerRequests,
        dormsAwaitingCount: dormsWaiting,
        reportedReviewsCount: reviewsWaiting,
        suspendedCount: 0,
        suspendedDorms: 0,
        suspendedAccounts: 0,
        totalWaiting: waiting,
        onSelectMenu: onSelectMenu ?? (_) {},
        activities: logs.map(ActivityRowData.fromLog).toList(),
      ),
    ),
  );
}

void main() {
  testWidgets('1. Dashboard shows the cards and how many items are waiting', (
    tester,
  ) async {
    useDesktopScreen(tester);
    await tester.pumpWidget(dashboard(dormsWaiting: 3, reviewsWaiting: 2));
    await tester.pumpAndSettle();

    expect(find.text('Owner requests'), findsOneWidget);
    expect(find.text('Dorms awaiting review'), findsOneWidget);
    expect(find.text('Reported reviews'), findsOneWidget);
    expect(find.text('5 items are waiting for your review.'), findsOneWidget);
  });

  testWidgets('2. Dashboard says nothing is waiting when all caught up', (
    tester,
  ) async {
    useDesktopScreen(tester);
    await tester.pumpWidget(dashboard());
    await tester.pumpAndSettle();

    expect(find.text('Nothing is waiting for you right now.'), findsOneWidget);
  });

  testWidgets('3. Recent activity lists the latest admin actions', (
    tester,
  ) async {
    useDesktopScreen(tester);
    await tester.pumpWidget(dashboard(logs: recentLogs));
    await tester.pumpAndSettle();

    expect(find.text('Recent activity'), findsOneWidget);
    expect(find.text('dormitory #8'), findsOneWidget);
    expect(find.text('verification #5'), findsOneWidget);
    expect(find.text('dormitory.approve'), findsOneWidget);
    expect(find.text('verification.approve'), findsOneWidget);
    expect(find.text('admin · 2026-11-17T16:03:31.000Z'), findsOneWidget);
  });

  testWidgets('4. Recent activity shows an empty message with no actions', (
    tester,
  ) async {
    useDesktopScreen(tester);
    await tester.pumpWidget(dashboard());
    await tester.pumpAndSettle();

    expect(find.text('No recent activity'), findsOneWidget);
  });

  testWidgets('5. Tapping a card opens the matching menu', (tester) async {
    useDesktopScreen(tester);
    final opened = <int>[];
    await tester.pumpWidget(
      dashboard(ownerRequests: 1, dormsWaiting: 2, onSelectMenu: opened.add),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Owner requests'));
    await tester.tap(find.text('Dorms awaiting review'));
    await tester.tap(find.text('Reported reviews'));
    await tester.pump();

    // 1 = Owner requests, 2 = Dorms, 4 = Reviews
    expect(opened, [1, 2, 4]);
  });

  testWidgets('6. View all opens the Activity log', (tester) async {
    useDesktopScreen(tester);
    final opened = <int>[];
    await tester.pumpWidget(
      dashboard(logs: recentLogs, onSelectMenu: opened.add),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('View all'));
    await tester.pump();

    expect(opened, [5]); // 5 = Activity log
  });
}
