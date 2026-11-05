import 'package:flutter/material.dart';

import '../../models/dormitory_details.dart';
import '../theme/owner_theme.dart';

/// ป้ายสถานะ (อนุมัติแล้ว / รอตรวจสอบ / ไม่ผ่าน)
class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});

  final DormitoryStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg) = switch (status) {
      DormitoryStatus.approved => ('อนุมัติแล้ว', OwnerColors.primaryText, OwnerColors.primaryTint),
      DormitoryStatus.pending => ('รอตรวจสอบ', OwnerColors.warning, OwnerColors.warningTint),
      DormitoryStatus.rejected => ('ไม่ผ่าน', OwnerColors.danger, OwnerColors.dangerTint),
    };
    return Pill(label, color: fg, background: bg);
  }
}

/// ป้ายกลมมนข้อความสั้น
class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.color = OwnerColors.primaryText, this.background = OwnerColors.primaryTint});

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// ช่องตัวเลขเล็ก ๆ ป้ายอยู่บน ค่าอยู่ล่าง
class MiniStat extends StatelessWidget {
  const MiniStat({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(color: OwnerColors.background, borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: text.bodySmall?.copyWith(color: OwnerColors.textMuted)),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// ป้ายสิ่งอำนวยความสะดวกที่หอมี
class AmenityWrap extends StatelessWidget {
  const AmenityWrap(this.amenities, {super.key});

  final Set<String> amenities;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final name in dormitoryAmenities)
          if (amenities.contains(name)) Pill(name, color: OwnerColors.navy, background: OwnerColors.chip),
      ],
    );
  }
}

/// แถบบอกขั้นตอนการสมัคร
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.step, required this.caption, this.total = 2});

  final int step;
  final int total;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: 'ขั้นที่ $step จาก $total',
          child: ExcludeSemantics(
            child: Row(
              children: [
                for (var i = 1; i <= total; i++) ...[
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: i <= step ? OwnerColors.primary : OwnerColors.fieldBorder,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  if (i < total) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(caption, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: OwnerColors.textMuted)),
      ],
    );
  }
}
