import 'package:flutter/material.dart';

import '../theme/owner_theme.dart';

/// แถบนำทางลอยด้านล่าง: หน้าหลัก, โปรไฟล์ และปุ่มเพิ่มหอ
class FloatingNav extends StatelessWidget {
  const FloatingNav({super.key, required this.index, required this.onSelect, required this.onAdd});

  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  static const _tabs = [
    ('หน้าหลัก', Icons.home_outlined),
    ('โปรไฟล์', Icons.account_circle_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: OwnerColors.surface,
            border: Border.all(color: OwnerColors.border),
            borderRadius: BorderRadius.circular(23),
            boxShadow: const [BoxShadow(color: Color(0x24183B56), blurRadius: 16, offset: Offset(0, 6))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _tabs.length; i++)
                _Tab(label: _tabs[i].$1, icon: _tabs[i].$2, selected: index == i, onTap: () => onSelect(i)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Tooltip(
          message: 'เพิ่มหอ',
          child: Material(
            color: OwnerColors.primary,
            shape: const CircleBorder(),
            elevation: 4,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onAdd,
              child: const SizedBox(width: 46, height: 46, child: Icon(Icons.add, color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.icon, required this.selected, required this.onTap});

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: InkWell(
          borderRadius: BorderRadius.circular(23),
          onTap: onTap,
          child: SizedBox(
            width: 70,
            height: 46,
            child: Center(
              child: Container(
                width: 56,
                height: 36,
                decoration: BoxDecoration(
                  color: selected ? OwnerColors.primaryTint : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, size: 22, color: selected ? OwnerColors.primary : OwnerColors.textMuted),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
