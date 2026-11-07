import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../services/app_services.dart';
import '../../ui/app_theme.dart';
import '../../ui/error_handling.dart';

/// ตรวจรีวิวที่รอการเผยแพร่: เผยแพร่ หรือซ่อน (ต้องระบุเหตุผล)
class AdminReviewsTab extends StatefulWidget {
  const AdminReviewsTab({super.key, required this.services});

  final AppServices services;

  @override
  State<AdminReviewsTab> createState() => _AdminReviewsTabState();
}

class _AdminReviewsTabState extends State<AdminReviewsTab> {
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
      final items = await _admin.reviews('pending');
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _publish(int id) async {
    try {
      await _admin.publishReview(id);
      await _load();
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    }
  }

  Future<void> _hide(int id) async {
    final reason = await askReason(context, 'เหตุผลที่ซ่อนรีวิว');
    if (reason == null) return;
    try {
      await _admin.hideReview(id, reason);
      await _load();
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รีวิวรอตรวจ'),
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
          ? const Center(child: Text('ไม่มีรีวิวรอตรวจ'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final r = _items[i];
                  final id = r['id'] as int;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${r['dormitory_name']}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '★' * (r['rating'] as int),
                            style: const TextStyle(
                              color: AppColors.warningText,
                            ),
                          ),
                          if ((r['body'] as String?)?.isNotEmpty ?? false)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('${r['body']}'),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => _hide(id),
                                child: const Text('ซ่อน'),
                              ),
                              FilledButton(
                                onPressed: () => _publish(id),
                                child: const Text('เผยแพร่'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

/// กล่องกรอกเหตุผล คืนค่า null ถ้ายกเลิกหรือไม่ได้กรอก
Future<String?> askReason(BuildContext context, String title) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        maxLines: 3,
        decoration: const InputDecoration(hintText: 'ระบุเหตุผล (จำเป็น)'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
          child: const Text('ยืนยัน'),
        ),
      ],
    ),
  );
  controller.dispose();
  if (result == null || result.isEmpty) return null;
  return result;
}
