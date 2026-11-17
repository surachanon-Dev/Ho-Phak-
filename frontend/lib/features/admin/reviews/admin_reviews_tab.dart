import 'package:flutter/material.dart';

import '../../controllers/admin_reviews_controller.dart';
import '../../services/admin_service.dart';
import '../../services/app_services.dart';
import '../../ui/error_handling.dart';

class AdminReviewsTab extends StatefulWidget {
  const AdminReviewsTab({super.key, required this.services});

  final AppServices services;

  @override
  State<AdminReviewsTab> createState() => _AdminReviewsTabState();
}

class _AdminReviewsTabState extends State<AdminReviewsTab> with SingleTickerProviderStateMixin {
  late final AdminReviewsController _c;
  late TabController _tabController;

  /// สถานะของแท็บตามที่หน้าจอใช้: pending | kept | hidden
  String get _currentStatus => switch (_c.status) {
    AdminReviewStatus.open => 'pending',
    AdminReviewStatus.kept => 'kept',
    AdminReviewStatus.hidden => 'hidden',
  };

  @override
  void initState() {
    super.initState();
    _c = AdminReviewsController(AdminService(widget.services.api));
    _c.addListener(() {
      if (mounted) setState(() {});
    });
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _c.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _c.selectStatus(AdminReviewStatus.values[_tabController.index]);
  }

  void _report() {
    if (!mounted) return;
    final error = _c.actionError ?? _c.loadError;
    if (error != null) showApiError(context, widget.services, error);
  }

  Future<void> _load() async {
    await _c.refresh();
    _report();
  }

  Future<void> _publish(int id) async {
    final ok = await _c.publishReview(id);
    if (!ok) _report();
  }

  Future<void> _hide(int id) async {
    final reason = await askReason(context, 'เหตุผลที่ซ่อนรีวิว');
    if (reason == null) return;
    final ok = await _c.hideReview(id, reason);
    if (!ok) _report();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Reported reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'รีเฟรช',
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _c.isLoading ? null : _load,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            width: double.infinity,
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              labelColor: const Color(0xFF1976D2),
              unselectedLabelColor: const Color(0xFF757575),
              indicatorColor: const Color(0xFF1976D2),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: 'Open'),
                Tab(text: 'Kept'),
                Tab(text: 'Hidden'),
              ],
            ),
          ),
        ),
      ),
      body: _buildBodyContent(),
    );
  }

  Widget _buildBodyContent() {
    if (_c.isLoading && _c.reviews.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoBanner(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE0E0E0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: 'All dorms',
                  items: const [
                    DropdownMenuItem(value: 'All dorms', child: Text('All dorms', style: TextStyle(fontSize: 14))),
                  ],
                  onChanged: (value) {},
                  icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: _c.reviews.isEmpty
              ? const Center(child: Text('ไม่มีรีวิวในสถานะนี้', style: TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _c.reviews.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, i) {
                      final r = _c.reviews[i];
                      final id = r['id'] as int;
                      return _buildReviewCard(r, id);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildInfoBanner() {
    String text = '';
    if (_currentStatus == 'pending') {
      text = 'Reviews go live as soon as students post them. Visible until hidden.';
    } else if (_currentStatus == 'kept') {
      text = 'Kept = report closed, review stays on the dorm page.';
    } else {
      text = 'Hidden reviews are removed from the dorm page.';
    }

    return Container(
      color: const Color(0xFFE3F2FD),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF1976D2), size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF1565C0), fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> r, int id) {
    final String dormName = r['dormitory_name']?.toString() ?? 'Unknown';
    final int rating = r['rating'] as int? ?? 0;
    final String body = r['body']?.toString() ?? '';
    final String author = r['author']?.toString() ?? 'Anonymous123';
    final String date = r['created_at']?.toString() ?? 'posted recently';
    final String reporter = r['reporter_name']?.toString() ?? 'Owner';
    final String reportReason = r['report_reason']?.toString() ?? 'No reason provided';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('★' * rating, style: const TextStyle(color: Colors.orange, fontSize: 14)),
                          const SizedBox(width: 6),
                          Text('$rating.0', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(dormName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('by $author · $date', style: const TextStyle(color: Color(0xFF757575), fontSize: 12)),
                    ],
                  ),
                ),
                _buildStatusBadge(),
              ],
            ),
          ),
          if (body.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(body, style: const TextStyle(fontSize: 14)),
            ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFEF6C00), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reported by $reporter', style: const TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text('"$reportReason"', style: const TextStyle(color: Color(0xFFEF6C00), fontSize: 12, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getActionText(),
                  style: const TextStyle(color: Color(0xFF757575), fontSize: 11),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: _buildActionButtons(id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    String text;
    Color bgColor, textColor;

    if (_currentStatus == 'pending') {
      text = 'Open report';
      bgColor = const Color(0xFFFFE0B2);
      textColor = const Color(0xFFEF6C00);
    } else if (_currentStatus == 'kept') {
      text = 'Kept';
      bgColor = const Color(0xFFE8F5E9);
      textColor = const Color(0xFF2E7D32);
    } else {
      text = 'Hidden';
      bgColor = const Color(0xFFEEEEEE);
      textColor = const Color(0xFF424242);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  String _getActionText() {
    if (_currentStatus == 'pending') {
      return 'Keep closes the report. Hide removes the review.';
    } else if (_currentStatus == 'kept') {
      return 'Review is visible on the dorm page.';
    } else {
      return 'Review is removed from the dorm page.';
    }
  }

  Widget _buildActionButtons(int id) {
    if (_currentStatus == 'pending') {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => _publish(id),
            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF616161), side: const BorderSide(color: Color(0xFFE0E0E0))),
            child: const Text('Keep review'),
          ),
          FilledButton(
            onPressed: () => _hide(id),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            child: const Text('Hide review'),
          ),
        ],
      );
    } else if (_currentStatus == 'kept') {
      return Align(
        alignment: Alignment.centerRight,
        child: FilledButton(
          onPressed: () => _hide(id),
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
          child: const Text('Hide review'),
        ),
      );
    } else {
      return Align(
        alignment: Alignment.centerRight,
        child: OutlinedButton(
          onPressed: () => _publish(id),
          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF616161), side: const BorderSide(color: Color(0xFFE0E0E0))),
          child: const Text('Unhide review'),
        ),
      );
    }
  }
}

Future<String?> askReason(BuildContext context, String title) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: const TextStyle(fontSize: 18)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Students will no longer see it. The owner is notified.',
            style: TextStyle(color: Color(0xFF616161), fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'ระบุเหตุผล (จำเป็น)',
              hintStyle: const TextStyle(fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
          child: const Text('ยืนยัน'),
        ),
      ],
    ),
  );
  controller.dispose();
  if (result == null || result.isEmpty) return null;
  return result;
}