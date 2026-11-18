import 'package:flutter/material.dart';

import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/core/theme/app_theme.dart';
import 'package:hopak_frontend/core/utils/error_handling.dart';
import 'package:hopak_frontend/features/notifications/notifications_screen.dart';
import 'package:hopak_frontend/features/owner/models/notification_prefs.dart';
import 'package:hopak_frontend/features/owner/notification_settings/notification_settings_controller.dart';

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
  late final NotificationSettingsController _c;

  @override
  void initState() {
    super.initState();
    _c = NotificationSettingsController(widget.services.account);
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

  Future<void> _load() async {
    final ok = await _c.load();
    if (!ok && mounted && _c.error != null) {
      showApiError(context, widget.services, _c.error!);
    }
  }

  Future<void> _set(NotificationPrefs next) async {
    final ok = await _c.update(next);
    if (!ok && mounted && _c.error != null) {
      showApiError(context, widget.services, _c.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _c.prefs;
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
