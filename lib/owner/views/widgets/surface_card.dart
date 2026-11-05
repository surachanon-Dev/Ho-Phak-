import 'package:flutter/material.dart';

import '../theme/owner_theme.dart';

/// กรอบขาวมุมมน ทำจาก Material เพื่อให้เอฟเฟกต์ตอนแตะของรายการข้างในมองเห็น
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = OwnerColors.surface,
    this.borderColor = OwnerColors.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OwnerRadius.card),
        side: BorderSide(color: borderColor),
      ),
      child: SizedBox(width: double.infinity, child: Padding(padding: padding, child: child)),
    );
  }
}

/// กรอบขาวที่มีหัวข้อ (และคำอธิบายสั้น ๆ ต่อท้ายได้)
class TitledCard extends StatelessWidget {
  const TitledCard({super.key, required this.title, required this.child, this.note});

  final String title;
  final String? note;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text.rich(
              TextSpan(
                text: title,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: OwnerColors.navy),
                children: [
                  if (note != null)
                    TextSpan(
                      text: '  · $note',
                      style: text.bodySmall?.copyWith(color: OwnerColors.textMuted),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
