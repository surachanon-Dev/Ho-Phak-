import 'package:flutter/material.dart';

import '../../models/dormitory.dart';
import '../../models/review.dart';
import '../../services/app_services.dart';
import '../../ui/app_theme.dart';
import '../../ui/error_handling.dart';
import '../../ui/status_style.dart';
import 'dashboard_screen.dart' show formatBaht;
import 'dormitory_form_screen.dart';

/// รายละเอียดหอพักฝั่งเจ้าของ: สถานะ, สวิตช์แสดงให้นักศึกษาเห็น,
/// ห้อง/ค่าน้ำ-ค่าไฟ, รีวิว (อ่านอย่างเดียว) และแก้ไข
/// pop(true) เมื่อมีการเปลี่ยนแปลง เพื่อให้หน้ารายการโหลดใหม่
class DormitoryDetailScreen extends StatefulWidget {
  const DormitoryDetailScreen({
    super.key,
    required this.services,
    required this.dormitoryId,
  });

  final AppServices services;
  final int dormitoryId;

  @override
  State<DormitoryDetailScreen> createState() => _DormitoryDetailScreenState();
}

class _DormitoryDetailScreenState extends State<DormitoryDetailScreen> {
  Dormitory? _dorm;
  List<OwnerReview> _reviews = [];
  bool _loading = true;
  bool _busy = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        widget.services.dormitories.get(widget.dormitoryId),
        widget.services.dormitories.reviews(widget.dormitoryId),
      ]);
      if (!mounted) return;
      setState(() {
        _dorm = results[0] as Dormitory;
        _reviews = results[1] as List<OwnerReview>;
      });
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleVisibility() async {
    setState(() => _busy = true);
    try {
      await widget.services.dormitories.toggleVisibility(widget.dormitoryId);
      _changed = true;
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _dorm?.status == DormStatus.published
                  ? 'Dorm is now visible to students'
                  : 'Dorm is now hidden from students',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit() async {
    final dorm = _dorm;
    if (dorm == null) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            DormitoryFormScreen(services: widget.services, existing: dorm),
      ),
    );
    if (changed == true) {
      _changed = true;
      await _load();
    }
  }

  void _contactAdmin() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Contact admin'),
        content: const Text(
          'The admin contact number has not been set yet (to be confirmed).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// ข้อความอธิบายสถานะ
  String _statusMessage(String status) => switch (status) {
    DormStatus.published => 'Students can see and contact this dorm.',
    DormStatus.pending =>
      'Waiting for admin review. Students will see it after approval (usually 1–2 days).',
    DormStatus.changesPending =>
      'Your changes are waiting for admin review. Students still see the previous version.',
    DormStatus.rejected => 'Admin did not approve this dorm. Edit it and submit again.',
    DormStatus.hidden => 'Students cannot find this dorm in search. Those who saved it or chatted with you will see it as "Unavailable".',
    DormStatus.suspended =>
      'Admin suspended this dorm. You cannot change its visibility. Contact admin to resolve this.',
    _ => '',
  };

  String _toggleNote(Dormitory d) => switch (d.status) {
    DormStatus.published => 'Turn off to hide this dorm from search',
    DormStatus.hidden => 'Turn on to show this dorm in search again',
    DormStatus.suspended => 'Locked while suspended',
    DormStatus.pending ||
    DormStatus.rejected => 'Available after admin approval',
    _ => 'Cannot be changed in this status',
  };

  double? get _avgRating => _reviews.isEmpty
      ? null
      : _reviews.fold<int>(0, (s, r) => s + r.rating) / _reviews.length;

  @override
  Widget build(BuildContext context) {
    final dorm = _dorm;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(dorm?.name ?? 'Dorm detail'),
          leading: BackButton(
            onPressed: () => Navigator.of(context).pop(_changed),
          ),
        ),
        body: _loading && dorm == null
            ? const Center(child: CircularProgressIndicator())
            : dorm == null
            ? const Center(child: Text('Dorm not found'))
            : AbsorbPointer(
                absorbing: _busy,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _Cover(dorm: dorm),
                    const SizedBox(height: 16),

                    // ---- สถานะ ----
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    DormStatus.label(dorm.status),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                                StatusChip(displayStatus: dorm.status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(_statusMessage(dorm.status)),
                            if (dorm.statusReason != null &&
                                dorm.statusReason!.isNotEmpty &&
                                (dorm.status == DormStatus.rejected ||
                                    dorm.status ==
                                        DormStatus.changesPending)) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.warningBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Admin note: ${dorm.statusReason}',
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            if (dorm.status == DormStatus.rejected ||
                                dorm.status == DormStatus.changesPending)
                              FilledButton(
                                onPressed: _edit,
                                child: const Text('Edit and resubmit'),
                              ),
                            if (dorm.status == DormStatus.suspended)
                              FilledButton(
                                onPressed: _contactAdmin,
                                child: const Text('Contact admin'),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ---- สวิตช์แสดงให้นักศึกษาเห็น ----
                    Card(
                      child: SwitchListTile(
                        title: const Text('Visible to students'),
                        subtitle: Text(_toggleNote(dorm)),
                        value: dorm.status == DormStatus.published,
                        onChanged: dorm.canToggleVisibility
                            ? (_) => _toggleVisibility()
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ลำดับกล่องตาม Figma (D-176): Location → Rooms → Utilities
                    _Section(
                      title: 'Dorm info',
                      children: [
                        _InfoRow(label: 'Zone', value: dorm.zone),
                        _InfoRow(
                          label: 'Price / month',
                          value: '${formatBaht(dorm.pricePerMonth)} THB',
                        ),
                        if (dorm.description != null)
                          _InfoRow(
                            label: 'Description',
                            value: dorm.description!,
                          ),
                      ],
                    ),

                    _Section(
                      title: 'Location',
                      children: [
                        _InfoRow(
                          label: 'Pin',
                          value: '${dorm.latitude}, ${dorm.longitude}',
                        ),
                        if (dorm.address != null)
                          _InfoRow(label: 'Address', value: dorm.address!),
                        if (dorm.contactPhone != null)
                          _InfoRow(
                            label: 'Contact phone',
                            value: dorm.contactPhone!,
                          ),
                      ],
                    ),

                    _Section(
                      title: 'Rooms',
                      children: [
                        _InfoRow(
                          label: 'Total rooms',
                          value: '${dorm.totalRooms}',
                        ),
                        _InfoRow(
                          label: 'Available now',
                          value: '${dorm.availableRooms}',
                        ),
                      ],
                    ),

                    _Section(
                      title: 'Utilities',
                      children: [
                        _InfoRow(
                          label: 'Water',
                          value: _billingText(
                            dorm.waterRate,
                            dorm.waterBillingType,
                          ),
                        ),
                        _InfoRow(
                          label: 'Electricity',
                          value: _billingText(
                            dorm.electricityRate,
                            dorm.electricityBillingType,
                          ),
                        ),
                      ],
                    ),

                    _Section(
                      title: _avgRating == null
                          ? 'Reviews'
                          : 'Reviews (${_avgRating!.toStringAsFixed(1)} ★ · ${_reviews.length})',
                      children: [
                        if (_reviews.isEmpty)
                          const Text('No published reviews yet')
                        else
                          ..._reviews.map(
                            (r) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${'★' * r.rating}  ${r.createdAt}'),
                                  if (r.body != null && r.body!.isNotEmpty)
                                    Text(r.body!),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 4),
                        const Text(
                          'Read only. Owners cannot reply to reviews.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    if (dorm.canEdit)
                      FilledButton.icon(
                        onPressed: _edit,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit dorm'),
                      )
                    else
                      const Text(
                        'This dorm is suspended and cannot be edited.',
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  String _billingText(double? rate, String? type) {
    if (rate == null || type == null) return 'Not specified';
    final unit = type == BillingType.perUnit ? 'THB/unit' : 'THB';
    return '$rate $unit (${BillingType.labelEn(type)})';
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.dorm});

  final Dormitory dorm;

  @override
  Widget build(BuildContext context) {
    final cover = dorm.images.isEmpty ? null : dorm.images.first.fullUrl;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: cover == null
            ? const ColoredBox(
                color: Colors.black12,
                child: Center(child: Text('No photos yet')),
              )
            : Image.network(
                cover,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: Colors.black12,
                  child: Icon(Icons.broken_image_outlined),
                ),
              ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
