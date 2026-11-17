import 'package:flutter/material.dart';

import '../../../app/session.dart';
import '../../../core/app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ui/ui.dart';
import '../dashboard/admin_dashboard_view.dart' show ActivityRowData;
import '../services/admin_service.dart';
import '../widgets/admin_page.dart';
import 'admin_activity_log_controller.dart';

/// ประวัติการทำงานของแอดมิน 100 รายการล่าสุด (อ่านอย่างเดียว)
class AdminLogsTab extends StatefulWidget {
  const AdminLogsTab({super.key, required this.services});

  final AppServices services;

  @override
  State<AdminLogsTab> createState() => _AdminLogsTabState();
}

class _AdminLogsTabState extends State<AdminLogsTab> {
  late final AdminActivityLogController _c;

  @override
  void initState() {
    super.initState();
    _c = AdminActivityLogController(AdminService(widget.services.api));
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
    await _c.refresh();
    if (mounted && _c.error != null) {
      showApiError(context, widget.services, _c.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _c.entries;
    final actions = _c.availableActions;

    return AdminPage(
      title: 'ประวัติการทำงาน',
      subtitle: 'การกระทำของแอดมิน 100 รายการล่าสุด',
      actions: [
        HeaderIconButton(
          tooltip: 'รีเฟรช',
          icon: Icons.refresh,
          onPressed: _c.isLoading ? null : _load,
        ),
      ],
      toolbar: actions.length < 2
          ? null
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'ทั้งหมด',
                    selected: _c.action == null,
                    onTap: () => _c.setFilters(since: _c.since),
                  ),
                  for (final a in actions)
                    _FilterChip(
                      label: a,
                      selected: _c.action == a,
                      onTap: () => _c.setFilters(action: a, since: _c.since),
                    ),
                ],
              ),
            ),
      child: _c.isLoading && items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
          ? const EmptyState(
              icon: Icons.history_toggle_off,
              tone: Tone.neutral,
              title: 'ยังไม่มีประวัติ',
              message: 'เมื่อแอดมินอนุมัติ ปฏิเสธ หรือระงับรายการ จะแสดงที่นี่',
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: AdminListView(
                itemCount: items.length,
                separator: 8,
                itemBuilder: (context, i) => _LogTile(entry: items[i]),
              ),
            ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: selected ? AppColors.primary : AppColors.textBody,
        ),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.entry});

  final Map<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    final row = ActivityRowData.fromLog(entry);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          IconBadge(icon: row.icon, tone: row.tone, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry['action'] ?? '-'}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${entry['admin_name'] ?? '-'} · '
                  '${entry['target_type'] ?? ''} #${entry['target_id'] ?? '-'}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            flex: 0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                '${entry['created_at'] ?? ''}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppColors.textFaint,
                  fontSize: 11.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
