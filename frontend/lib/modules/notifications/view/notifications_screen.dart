import 'package:flutter/material.dart';

import '../controllers/notifications_controller.dart';
import '../../../shared/models/notification.dart';
import '../../../core/app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../app/session.dart';

/// การแจ้งเตือน: แสดง 50 รายการล่าสุด กดแล้วทำเครื่องหมายว่าอ่านแล้ว
/// หมายเหตุ: หน้า "ตั้งค่าการแจ้งเตือน" ในดีไซน์ยังไม่มี API จึงยังไม่ทำ
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationsController _c;

  @override
  void initState() {
    super.initState();
    _c = NotificationsController(widget.services.notifications);
    _c.addListener(_onChanged);
    _c.load().then((_) {
      if (mounted && _c.error != null) {
        showApiError(context, widget.services, _c.error!);
      }
    });
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

  Future<void> _open(AppNotification n) async {
    final ok = await _c.open(n);
    if (!ok && mounted && _c.error != null) {
      showApiError(context, widget.services, _c.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('การแจ้งเตือน')),
      body: RefreshIndicator(
        onRefresh: _c.load,
        child: _c.showFullLoader
            ? const Center(child: CircularProgressIndicator())
            : _c.items.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('ยังไม่มีการแจ้งเตือน')),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _c.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final n = _c.items[i];
                  return Card(
                    child: ListTile(
                      onTap: () => _open(n),
                      leading: Icon(
                        n.isRead
                            ? Icons.notifications_none
                            : Icons.notifications_active,
                        color: n.isRead
                            ? AppColors.textMuted
                            : AppColors.primary,
                      ),
                      title: Text(
                        n.title,
                        style: TextStyle(
                          fontWeight: n.isRead
                              ? FontWeight.w500
                              : FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(n.body ?? n.createdAt),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
