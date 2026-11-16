import 'package:flutter/material.dart';

import '../../services/app_services.dart';
import '../../services/owner_extras.dart';
import '../../ui/app_theme.dart';
import '../../ui/error_handling.dart';
import '../notifications_screen.dart';

/// ตั้งค่าแจ้งเตือน 3 สวิตช์ (Figma O-9) + ทางเข้าดูรายการแจ้งเตือนที่มีอยู่
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  NotificationPrefs? _prefs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await widget.services.extras.notificationPrefs();
      if (mounted) setState(() => _prefs = p);
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    }
  }

  Future<void> _set(NotificationPrefs next) async {
    final before = _prefs;
    setState(() => _prefs = next);
    try {
      await widget.services.extras.saveNotificationPrefs(next);
    } catch (e) {
      if (!mounted) return;
      setState(() => _prefs = before);
      showApiError(context, widget.services, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _prefs;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification settings'),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: p == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Column(
                    children: [
                      _tile(
                        'New messages',
                        'When a student sends you a message',
                        p.messages,
                        (v) => _set(p.copyWith(messages: v)),
                      ),
                      const Divider(height: 1),
                      _tile(
                        'Approval updates',
                        'When admin approves or rejects your dorm or changes',
                        p.approvals,
                        (v) => _set(p.copyWith(approvals: v)),
                      ),
                      const Divider(height: 1),
                      _tile(
                        'New reviews',
                        'When a student reviews one of your dorms',
                        p.reviews,
                        (v) => _set(p.copyWith(reviews: v)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            NotificationsScreen(services: widget.services),
                      ),
                    ),
                    child: const Text('See recent notifications'),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _tile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) => SwitchListTile(
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(
      subtitle,
      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
    ),
    value: value,
    onChanged: onChanged,
  );
}
