import 'package:flutter/material.dart';

import 'package:hopak_frontend/features/admin/activity_log/activity_log_controller.dart';
import 'package:hopak_frontend/features/admin/services/admin_service.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/core/theme/app_theme.dart';
import 'package:hopak_frontend/core/utils/error_handling.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติการทำงาน'),
        actions: [
          IconButton(
            tooltip: 'รีเฟรช',
            icon: const Icon(Icons.refresh),
            onPressed: _c.isLoading ? null : _load,
          ),
        ],
      ),
      body: _c.isLoading && items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
          ? const Center(child: Text('ยังไม่มีประวัติ'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final l = items[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${l['action'] ?? '-'}'),
                    subtitle: Text(
                      '${l['admin_name'] ?? '-'} · '
                      '${l['target_type'] ?? ''} #${l['target_id'] ?? '-'}',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    trailing: Text(
                      '${l['created_at'] ?? ''}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
