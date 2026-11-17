import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/ui/ui.dart';

/// ปุ่มแท็บแบบเม็ดยาพร้อมตัวเลข (Pending / Approved / Rejected)
class RequestTabButton extends StatelessWidget {
  const RequestTabButton({
    super.key,
    required this.label,
    this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm + 2),
      elevation: selected ? 1 : 0,
      shadowColor: const Color(0x220F172A),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm + 2),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? AppColors.text : AppColors.textMuted,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// กรอบรวมปุ่มแท็บ (segmented control)
class RequestTabBar extends StatelessWidget {
  const RequestTabBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFECEEF5),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

class RequestStatusPill extends StatelessWidget {
  const RequestStatusPill({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (tone, icon) = switch (status) {
      'Rejected' => (Tone.danger, Icons.close_rounded),
      'Approved' => (Tone.success, Icons.check_rounded),
      _ => (Tone.warning, Icons.schedule_rounded),
    };
    return ToneBadge(label: status, tone: tone, icon: icon);
  }
}

/// หัวหน้ารายละเอียด: ลิงก์ย้อนกลับ + เส้นทาง + หัวข้อ
class BreadcrumbHeader extends StatelessWidget {
  const BreadcrumbHeader({
    super.key,
    required this.parent,
    required this.current,
    required this.title,
    required this.onBack,
    this.trailing,
  });

  final String parent;
  final String current;
  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.outlined(
          tooltip: 'Back',
          onPressed: onBack,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            side: const BorderSide(color: AppColors.border),
          ),
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: InkWell(
                      onTap: onBack,
                      child: Text(
                        parent,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.chevron_right,
                      size: 14,
                      color: AppColors.textFaint,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      current,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class ApplicantHeader extends StatelessWidget {
  const ApplicantHeader({
    super.key,
    required this.initials,
    required this.name,
    required this.subtitle,
    this.trailing,
  });

  final String initials;
  final String name;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            gradient: AppColors.brandGradient,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    this.value,
    this.customValue,
    this.icon,
  });

  final String label;
  final String? value;
  final Widget? customValue;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.textFaint),
            const SizedBox(width: 10),
          ],
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child:
                  customValue ??
                  Text(
                    value ?? '',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ลิงก์ชื่อไฟล์เอกสาร กดแล้วเปิดดูเอกสาร
class DocumentLink extends StatelessWidget {
  const DocumentLink({super.key, required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = name != '-';
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: enabled ? AppColors.primarySoft : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.description_outlined,
              size: 15,
              color: enabled ? AppColors.primary : AppColors.textFaint,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: enabled ? AppColors.primary : AppColors.textFaint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
