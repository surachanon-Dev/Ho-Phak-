import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../widgets/ui/ui.dart';

/// ดรอปดาวน์ตัวกรองแบบกรอบมน
class FilterDropdown extends StatelessWidget {
  const FilterDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.icon,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: IntrinsicWidth(
        child: Container(
          height: 44,
          padding: const EdgeInsets.only(left: 12, right: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17, color: AppColors.textMuted),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    icon: const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                    onChanged: onChanged,
                    items: [
                      for (final item in items)
                        DropdownMenuItem(
                          value: item,
                          child: Text(item, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RolePill extends StatelessWidget {
  const RolePill({super.key, required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final (tone, icon) = switch (role) {
      'Owner' => (Tone.primary, Icons.home_work_outlined),
      'Admin' => (Tone.warning, Icons.shield_outlined),
      _ => (Tone.info, Icons.school_outlined),
    };
    return ToneBadge(label: role, tone: tone, icon: icon);
  }
}

class UserStatusPill extends StatelessWidget {
  const UserStatusPill({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final suspended = status == 'Suspended';
    return ToneBadge(
      label: status,
      tone: suspended ? Tone.danger : Tone.success,
      solid: suspended,
    );
  }
}
