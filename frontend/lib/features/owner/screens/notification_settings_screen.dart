import 'package:flutter/material.dart';

import '../../../core/app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../app/session.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../models/notification_prefs.dart';
import '../controllers/notification_settings_controller.dart';
import '../../../shared/widgets/ui/ui.dart';
import '../widgets/owner_ui.dart';

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
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: p == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                OwnerBody(
                  maxWidth: 620,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SettingsGroup(
                        title: 'Notify me about',
                        children: [
                          _tile(
                            Icons.chat_bubble_outline_rounded,
                            Tone.primary,
                            'New messages',
                            'When a student sends you a message',
                            p.messages,
                            (v) => _set(p.copyWith(messages: v)),
                          ),
                          _tile(
                            Icons.fact_check_outlined,
                            Tone.success,
                            'Approval updates',
                            'When admin approves or rejects your dorm or changes',
                            p.approvals,
                            (v) => _set(p.copyWith(approvals: v)),
                          ),
                          _tile(
                            Icons.star_outline_rounded,
                            Tone.warning,
                            'New reviews',
                            'When a student reviews one of your dorms',
                            p.reviews,
                            (v) => _set(p.copyWith(reviews: v)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AppCard(
                        padding: EdgeInsets.zero,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                NotificationsScreen(services: widget.services),
                          ),
                        ),
                        child: const ListTile(
                          leading: IconBadge(
                            icon: Icons.notifications_none_rounded,
                            tone: Tone.info,
                            size: 36,
                          ),
                          title: Text('See recent notifications'),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textFaint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _tile(
    IconData icon,
    Tone tone,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) => SwitchListTile(
    contentPadding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
    secondary: IconBadge(icon: icon, tone: tone, size: 36),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(
      subtitle,
      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
    ),
    value: value,
    onChanged: onChanged,
  );
}
