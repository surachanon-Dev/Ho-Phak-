import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../services/app_services.dart';
import '../../ui/app_theme.dart';
import '../../ui/error_handling.dart';

/// ประวัติการทำงานของแอดมิน 100 รายการล่าสุด (อ่านอย่างเดียว)
class AdminLogsTab extends StatefulWidget {
  const AdminLogsTab({super.key, required this.services});

  final AppServices services;

  @override
  State<AdminLogsTab> createState() => _AdminLogsTabState();
}

class _AdminLogsTabState extends State<AdminLogsTab> {
  late final AdminService _admin = AdminService(widget.services.api);
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _admin.logs();
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติการทำงาน'),
        actions: [
          IconButton(
            tooltip: 'รีเฟรช',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading && _items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(child: Text('ยังไม่มีประวัติ'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final l = _items[i];
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
