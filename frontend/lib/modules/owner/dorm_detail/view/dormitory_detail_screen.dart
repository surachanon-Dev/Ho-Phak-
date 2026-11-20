import 'package:flutter/material.dart';

import '../../../../model/dormitory.dart';
import '../../../../core/app_services.dart';
import '../controller/owner_dorm_detail_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../app/session.dart';
import '../../../../core/utils/status_style.dart';
import '../../../../core/utils/format.dart';
import '../../../../widgets/dorm_map.dart';
import '../../dashboard/view/dashboard_screen.dart' show formatBaht;
import '../../my_reviews/view/my_reviews_screen.dart';
import '../../dorm_form/view/dormitory_form_screen.dart';
import '../../../../model/dorm_utilities.dart';
import '../../../../widgets/ui/ui.dart';
import '../../widgets/owner_ui.dart';

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
  late final OwnerDormDetailController _c;

  @override
  void initState() {
    super.initState();
    _c = OwnerDormDetailController(
      dormitoryId: widget.dormitoryId,
      dorms: widget.services.dormitories,
    );
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

  Future<void> _toggleVisibility() async {
    final ok = await _c.toggleVisibility();
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _c.dorm?.status == DormStatus.published
                ? 'Dorm is now visible to students'
                : 'Dorm is now hidden from students',
          ),
        ),
      );
    } else if (_c.error != null) {
      showApiError(context, widget.services, _c.error!);
    }
  }

  Future<void> _edit() async {
    final dorm = _c.dorm;
    if (dorm == null) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            DormitoryFormScreen(services: widget.services, existing: dorm),
      ),
    );
    if (changed == true) await _c.reloadAfterEdit();
  }

  /// ลบหอ (Figma O-4): ยืนยันก่อน แล้วกลับไปหน้ารายการ
  Future<void> _confirmDelete() async {
    final dorm = _c.dorm;
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
    final deleted = await _c.delete();
    if (!mounted) return;
    if (deleted) {
      Navigator.of(context).pop(true);
    } else if (_c.error != null) {
      showApiError(context, widget.services, _c.error!);
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
    DormStatus.pending => 'Waiting for admin review. Students will see it after approval (usually 1–2 days).',
    DormStatus.changesPending => 'Your changes are waiting for admin review. Students still see the previous version.',
    DormStatus.rejected =>
      'Admin did not approve this dorm. Edit it and submit again.',
    DormStatus.hidden => 'Students cannot find this dorm in search. Those who saved it or chatted with you will see it as "Unavailable".',
    DormStatus.suspended => 'Admin suspended this dorm. You cannot change its visibility. Contact admin to resolve this.',
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

  /// ไอคอนในกล่องสถานะ (วงกลมสีตามสถานะ ตาม Figma)
  IconData _statusIcon(String status) => switch (status) {
    DormStatus.published => Icons.check,
    DormStatus.pending || DormStatus.changesPending => Icons.schedule,
    DormStatus.rejected => Icons.close,
    DormStatus.suspended => Icons.block,
    _ => Icons.visibility_off_outlined,
  };

  Tone _statusTone(String status) => switch (status) {
    DormStatus.published => Tone.success,
    DormStatus.pending => Tone.warning,
    DormStatus.changesPending => Tone.violet,
    DormStatus.rejected || DormStatus.suspended => Tone.danger,
    _ => Tone.neutral,
  };

  @override
  Widget build(BuildContext context) {
    final dorm = _c.dorm;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_c.changed);
      },
      child: Scaffold(
        body: _c.loading && dorm == null
            ? const Center(child: CircularProgressIndicator())
            : dorm == null
            ? EmptyState(
                icon: Icons.search_off_rounded,
                tone: Tone.neutral,
                title: 'Dorm not found',
                action: TextButton(
                  onPressed: () => Navigator.of(context).pop(_c.changed),
                  child: const Text('Back'),
                ),
              )
            : AbsorbPointer(
                absorbing: _c.busy,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _CoverHeader(
                      dorm: dorm,
                      onBack: () => Navigator.of(context).pop(_c.changed),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -28),
                      child: OwnerBody(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                          child: _body(dorm),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _body(Dormitory dorm) {
    final tone = _statusTone(dorm.status);
    final hasReason =
        dorm.statusReason != null &&
        dorm.statusReason!.isNotEmpty &&
        (dorm.status == DormStatus.rejected ||
            dorm.status == DormStatus.changesPending ||
            dorm.status == DormStatus.suspended ||
            // เผยแพร่/ซ่อนอยู่แต่ฉบับแก้ไขล่าสุดถูกปฏิเสธ
            dorm.status == DormStatus.published ||
            dorm.status == DormStatus.hidden);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---- ชื่อ ราคา และตัวเลขหลัก ----
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      dorm.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(displayStatus: dorm.status),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.place_outlined,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    zoneLabel(dorm.zone),
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _Metric(
                    label: 'per month',
                    value: '฿${formatBaht(dorm.pricePerMonth)}',
                    color: AppColors.primary,
                  ),
                  _Metric(
                    label: 'available',
                    value: '${dorm.availableRooms}/${dorm.totalRooms}',
                    color: dorm.availableRooms > 0
                        ? AppColors.success
                        : AppColors.textMuted,
                  ),
                  _Metric(
                    label: 'avg. rating',
                    value: _c.averageRating == null
                        ? '–'
                        : _c.averageRating!.toStringAsFixed(1),
                    color: const Color(0xFFD97706),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ---- สถานะ ----
        AppCard(
          padding: const EdgeInsets.all(16),
          color: tone.bg,
          borderColor: tone.fg.withValues(alpha: 0.25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: dorm.status == DormStatus.suspended
                          ? tone.fg
                          : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _statusIcon(dorm.status),
                      size: 20,
                      color: dorm.status == DormStatus.suspended
                          ? Colors.white
                          : tone.fg,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      DormStatus.label(dorm.status),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: tone.fg,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _statusMessage(dorm.status),
                style: const TextStyle(color: AppColors.textBody, height: 1.45),
              ),
              if (hasReason) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                  ),
                  child: Text('Admin note: ${dorm.statusReason}'),
                ),
              ],
              if (dorm.status == DormStatus.rejected ||
                  dorm.status == DormStatus.changesPending) ...[
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
        const SizedBox(height: 12),

        // ---- สวิตช์แสดงให้นักศึกษาเห็น ----
        AppCard(
          padding: EdgeInsets.zero,
          child: SwitchListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
            secondary: IconBadge(
              icon: dorm.status == DormStatus.published
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              tone: dorm.status == DormStatus.published
                  ? Tone.success
                  : Tone.neutral,
            ),
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

        // ลำดับกล่อง: Location → Rooms → Utilities → Reviews
        _Section(
          title: 'Location',
          icon: Icons.map_outlined,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: DormLocationMap(dorm: dorm, height: 140),
            ),
            const SizedBox(height: 10),
            Text(
              [
                if (dorm.address != null && dorm.address!.isNotEmpty)
                  dorm.address!,
                '${kmFromMfu(dorm.latitude, dorm.longitude)} km from MFU',
              ].join(' · '),
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            if (dorm.contactPhone != null && dorm.contactPhone!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.phone_outlined,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dorm.contactPhone!,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ],
        ),
        if (dorm.description != null && dorm.description!.isNotEmpty)
          _Section(
            title: 'Description',
            icon: Icons.notes_rounded,
            children: [
              Text(
                dorm.description!,
                style: const TextStyle(height: 1.5, color: AppColors.textBody),
              ),
            ],
          ),
        _Section(
          title: 'Rooms',
          icon: Icons.meeting_room_outlined,
          children: [
            _InfoRow(label: 'Total rooms', value: '${dorm.totalRooms}'),
            _InfoRow(label: 'Available now', value: '${dorm.availableRooms}'),
          ],
        ),
        _Section(
          title: 'Utilities',
          icon: Icons.bolt_outlined,
          children: [
            _InfoRow(
              label: 'Water',
              icon: Icons.water_drop_outlined,
              value: _billingText(
                dorm.waterRate,
                dorm.waterBillingType,
                _c.utilities?.water,
              ),
            ),
            _InfoRow(
              label: 'Electricity',
              icon: Icons.electric_bolt_outlined,
              value: _billingText(
                dorm.electricityRate,
                dorm.electricityBillingType,
                _c.utilities?.electricity,
              ),
            ),
          ],
        ),
        if (_c.amenities.isNotEmpty)
          _Section(
            title: 'Amenities',
            icon: Icons.sell_outlined,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in _c.amenities)
                    ToneBadge(
                      label: a.name,
                      tone: Tone.primary,
                      icon: Icons.check_rounded,
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
          const NoticeBanner(
            tone: Tone.danger,
            message: 'This dorm is suspended and cannot be edited.',
          ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _confirmDelete,
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete dorm'),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  /// กล่องรีวิว: ดาวเฉลี่ย + "See all" + รีวิวล่าสุด 1 รายการ (อ่านอย่างเดียว)
  Widget _reviewsCard() {
    final latest = _c.latestReview;
    return _Section(
      title: 'Reviews',
      icon: Icons.star_outline_rounded,
      trailing: _c.averageRating == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 18,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 3),
                Text(
                  '${_c.averageRating!.toStringAsFixed(1)} (${_c.reviews.length})',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 6),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          MyReviewsScreen(services: widget.services),
                    ),
                  ),
                  child: const Text('See all ›'),
                ),
              ],
            ),
      children: [
        if (latest == null)
          const Text(
            'No published reviews yet',
            style: TextStyle(color: AppColors.textMuted),
          )
        else if (latest.body != null && latest.body!.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              '“${latest.body}” · ${relativeDay(latest.createdAt)}',
              style: const TextStyle(color: AppColors.textBody, height: 1.45),
            ),
          ),
        const SizedBox(height: 8),
        const Text(
          'Read-only — owners can’t reply to reviews.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
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

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// หัวหน้า: รูปปกเต็มความกว้าง + ปุ่มย้อนกลับกลม + ตัวนับรูป
class _CoverHeader extends StatelessWidget {
  const _CoverHeader({required this.dorm, required this.onBack});

  final Dormitory dorm;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final cover = dorm.images.isEmpty ? null : dorm.images.first.fullUrl;
    return SizedBox(
      height: 250,
      child: Stack(
        fit: StackFit.expand,
        children: [
          cover == null
              ? Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.brandGradient,
                  ),
                  alignment: Alignment.center,
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        color: Color(0xCCFFFFFF),
                        size: 34,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'No photos yet',
                        style: TextStyle(color: Color(0xDDFFFFFF)),
                      ),
                    ],
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
                  elevation: 2,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onBack,
                    child: const SizedBox(
                      width: 42,
                      height: 42,
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.text,
                      ),
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
  const _Section({
    required this.title,
    required this.children,
    this.icon,
    this.trailing,
  });

  final String title;
  final IconData? icon;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionTitle(title, icon: icon, trailing: trailing),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// แถวป้าย-ค่า: ป้ายสีเทาชิดซ้าย ค่าตัวหนาชิดขวา
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.textFaint),
            const SizedBox(width: 8),
          ],
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
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
