import 'package:flutter/material.dart';

import '../models/notification.dart';
import '../services/app_services.dart';
import '../ui/app_theme.dart';
import '../ui/error_handling.dart';

/// การแจ้งเตือน: แสดง 50 รายการล่าสุด กดแล้วทำเครื่องหมายว่าอ่านแล้ว
/// หมายเหตุ: หน้า "ตั้งค่าการแจ้งเตือน" ในดีไซน์ยังไม่มี API จึงยังไม่ทำ
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await widget.services.notifications.list();
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(AppNotification n) async {
    if (!n.isRead) {
      try {
        await widget.services.notifications.markRead(n.id);
      } catch (e) {
        if (mounted) showApiError(context, widget.services, e);
      }
    }
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('การแจ้งเตือน')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading && _items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('ยังไม่มีการแจ้งเตือน')),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final n = _items[i];
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
