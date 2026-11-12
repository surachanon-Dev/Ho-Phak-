import 'package:flutter/material.dart';

import '../../models/dormitory.dart';
import '../../models/review.dart';
import '../../services/app_services.dart';
import '../../services/owner_extras.dart';
import '../../ui/app_theme.dart';
import '../../ui/error_handling.dart';
import '../../ui/status_style.dart';
import '../../ui/format.dart';
import '../../widgets/dorm_map.dart';
import 'dashboard_screen.dart' show formatBaht;
import 'my_reviews_screen.dart';
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
  List<Amenity> _amenities = [];
  DormUtilities? _utilities;
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
      final dorm = results[0] as Dormitory;
      final extras = widget.services.extras;
      final catalog = await extras.amenities();
      final ids = (await extras.dormAmenityIds(dorm.id, dorm.amenityIds))
          .toSet();
      final util = await extras.utilities(dorm.id);
      if (!mounted) return;
      setState(() {
        _dorm = dorm;
        _reviews = results[1] as List<OwnerReview>;
        _amenities = catalog.where((a) => ids.contains(a.id)).toList();
        _utilities = util;
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

  /// ลบหอ (Figma O-4): ยืนยันก่อน แล้วกลับไปหน้ารายการ
  Future<void> _confirmDelete() async {
    final dorm = _dorm;
    if (dorm == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Color(0xFFFDE2E2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.delete_outline, color: AppColors.danger),
        ),
        title: const Text('Delete this dorm?', textAlign: TextAlign.center),
        content: Text(
          '${dorm.name}, its photos and reviews will be removed for '
          'everyone. This can\u2019t be undone.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await widget.services.dormitories.delete(dorm.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showApiError(context, widget.services, e);
    } finally {
      if (mounted) setState(() => _busy = false);
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

  /// ไอคอนในกล่องสถานะ (วงกลมสีตามสถานะ ตาม Figma)
  IconData _statusIcon(String status) => switch (status) {
    DormStatus.published => Icons.check,
    DormStatus.pending || DormStatus.changesPending => Icons.schedule,
    DormStatus.rejected => Icons.close,
    DormStatus.suspended => Icons.block,
    _ => Icons.visibility_off_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final dorm = _dorm;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        body: _loading && dorm == null
            ? const Center(child: CircularProgressIndicator())
            : dorm == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Dorm not found'),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(_changed),
                      child: const Text('Back'),
                    ),
                  ],
                ),
              )
            : AbsorbPointer(
                absorbing: _busy,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _CoverHeader(
                      dorm: dorm,
                      onBack: () => Navigator.of(context).pop(_changed),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            dorm.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${dorm.zone} · ${formatBaht(dorm.pricePerMonth)} THB/month',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
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
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: statusStyle(dorm.status).bg,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _statusIcon(dorm.status),
                                          size: 20,
                                          color:
                                              dorm.status ==
                                                  DormStatus.suspended
                                              ? Colors.white
                                              : statusStyle(dorm.status).fg,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          DormStatus.label(dorm.status),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      StatusChip(displayStatus: dorm.status),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _statusMessage(dorm.status),
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
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
                                  if (dorm.status == DormStatus.rejected ||
                                      dorm.status ==
                                          DormStatus.changesPending) ...[
                                    const SizedBox(height: 12),
                                    FilledButton(
                                      onPressed: _edit,
                                      child: const Text('Edit and resubmit'),
                                    ),
                                  ],
                                  if (dorm.status == DormStatus.suspended) ...[
                                    const SizedBox(height: 12),
                                    FilledButton(
                                      onPressed: _contactAdmin,
                                      child: const Text('Contact admin'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ---- สวิตช์แสดงให้นักศึกษาเห็น ----
                          Card(
                            child: SwitchListTile(
                              title: const Text(
                                'Visible to students',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(_toggleNote(dorm)),
                              value: dorm.status == DormStatus.published,
                              onChanged: dorm.canToggleVisibility
                                  ? (_) => _toggleVisibility()
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ลำดับกล่องตาม Figma (D-176):
                          // Location → Rooms → Utilities → Reviews
                          _Section(
                            title: 'Location',
                            children: [
                              DormLocationMap(dorm: dorm, height: 120),
                              const SizedBox(height: 10),
                              Text(
                                [
                                  if (dorm.address != null &&
                                      dorm.address!.isNotEmpty)
                                    dorm.address!,
                                  '${kmFromMfu(dorm.latitude, dorm.longitude)} km from MFU',
                                ].join(' · '),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              if (dorm.contactPhone != null &&
                                  dorm.contactPhone!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone_outlined,
                                      size: 18,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(dorm.contactPhone!),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          if (dorm.description != null &&
                              dorm.description!.isNotEmpty)
                            _Section(
                              title: 'Description',
                              children: [Text(dorm.description!)],
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
                                  _utilities?.water,
                                ),
                              ),
                              _InfoRow(
                                label: 'Electricity',
                                value: _billingText(
                                  dorm.electricityRate,
                                  dorm.electricityBillingType,
                                  _utilities?.electricity,
                                ),
                              ),
                            ],
                          ),
                          if (_amenities.isNotEmpty)
                            _Section(
                              title: 'Amenities',
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final a in _amenities)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primarySoft,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          a.name,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          _reviewsCard(),
                          const SizedBox(height: 4),
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
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _confirmDelete,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.danger,
                            ),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Delete dorm'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  /// กล่องรีวิว: ดาวเฉลี่ย + "See all" + รีวิวล่าสุด 1 รายการ (อ่านอย่างเดียว)
  Widget _reviewsCard() {
    final latest = _reviews.isEmpty ? null : _reviews.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Reviews',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (_avgRating != null) ...[
                    const Icon(Icons.star, size: 18, color: Color(0xFFF5A623)),
                    const SizedBox(width: 4),
                    Text(
                      '${_avgRating!.toStringAsFixed(1)} (${_reviews.length})',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              MyReviewsScreen(services: widget.services),
                        ),
                      ),
                      child: const Text(
                        'See all ›',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              if (latest == null)
                const Text('No published reviews yet')
              else if (latest.body != null && latest.body!.isNotEmpty)
                Text(
                  '“${latest.body}” · ${relativeDay(latest.createdAt)}',
                  style: const TextStyle(color: Color(0xFF374151)),
                ),
              const SizedBox(height: 6),
              const Text(
                'Read-only — owners can’t reply to reviews.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _billingText(double? rate, String? type, UtilityMode? saved) {
    if (rate == null || type == null) {
      return utilityModeFor(rate: rate, saved: saved) == UtilityMode.included
          ? 'Included in rent'
          : 'Not specified';
    }
    final unit = type == BillingType.perUnit ? 'THB / unit' : 'THB';
    final value = rate == rate.truncateToDouble()
        ? rate.toStringAsFixed(0)
        : rate.toString();
    return '$value $unit';
  }
}

/// หัวหน้า: รูปปกเต็มความกว้าง + ปุ่มย้อนกลับกลม + ตัวนับรูป (ตาม Figma O-2)
class _CoverHeader extends StatelessWidget {
  const _CoverHeader({required this.dorm, required this.onBack});

  final Dormitory dorm;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final cover = dorm.images.isEmpty ? null : dorm.images.first.fullUrl;
    return SizedBox(
      height: 240,
      child: Stack(
        fit: StackFit.expand,
        children: [
          cover == null
              ? const ColoredBox(
                  color: Color(0xFFDDE2EA),
                  child: Center(
                    child: Text(
                      'No photos yet',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                )
              : Image.network(
                  cover,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const ColoredBox(
                    color: Color(0xFFDDE2EA),
                    child: Icon(Icons.broken_image_outlined),
                  ),
                ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 1,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onBack,
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.chevron_left, color: Color(0xFF111827)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (dorm.images.isNotEmpty)
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '1 / ${dorm.images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// แถวป้าย-ค่า: ป้ายสีเทาชิดซ้าย ค่าตัวหนาชิดขวา (ตาม Figma)
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
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
