import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/activity.dart';
import '../../services/notification_service.dart';
import '../widgets/common.dart';

/// notifications table for the logged-in user
class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  late Future<List<AppNotification>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<NotificationService>().list();
  }

  void _reload() => setState(() => _future = context.read<NotificationService>().list());

  IconData _icon(String type) => switch (type) {
        'dormitory_rejected' => Icons.cancel_outlined,
        'dormitory_suspended' => Icons.block,
        'review_status' => Icons.rate_review_outlined,
        _ => Icons.notifications_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final service = context.read<NotificationService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('การแจ้งเตือน'),
        actions: [
          TextButton(
            onPressed: () async {
              await service.markAllRead();
              _reload();
            },
            child: const Text('อ่านทั้งหมด', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: FutureBuilder<List<AppNotification>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return ErrorRetry(message: snap.error.toString(), onRetry: _reload);
          final items = snap.data!;
          if (items.isEmpty) return const EmptyState(icon: Icons.notifications_off_outlined, message: 'ยังไม่มีการแจ้งเตือน');
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final n = items[i];
              return Card(
                color: n.isRead ? null : AppColors.teal.withValues(alpha: 0.08),
                child: ListTile(
                  leading: Icon(_icon(n.type), color: n.isRead ? AppColors.muted : AppColors.teal),
                  title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold)),
                  subtitle: Text('${n.body ?? ''}${n.body == null ? '' : '\n'}${formatDateTime(n.createdAt)}'),
                  isThreeLine: n.body != null,
                  onTap: () async {
                    await service.markRead(n.id);
                    _reload();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
