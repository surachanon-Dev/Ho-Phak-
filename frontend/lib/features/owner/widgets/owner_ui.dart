import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// ความกว้างสูงสุดของเนื้อหาหน้า owner (อ่านง่ายบนจอกว้าง)
const double kOwnerContentWidth = 760;

/// ห่อเนื้อหาให้กว้างไม่เกิน [kOwnerContentWidth] และอยู่กลางจอ
class OwnerBody extends StatelessWidget {
  const OwnerBody({super.key, required this.child, this.maxWidth});

  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? kOwnerContentWidth),
        child: child,
      ),
    );
  }
}

/// รูปปกหอ (มีกรอบสำรองเมื่อไม่มีรูปหรือโหลดไม่ได้)
class DormCover extends StatelessWidget {
  const DormCover({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.radius = AppRadius.md,
  });

  final String? url;
  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    Widget placeholder(IconData icon) => Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE0E7FF), Color(0xFFEDE9FE)],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: const Color(0xFF8B8FD6), size: 30),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: url == null
            ? placeholder(Icons.apartment_rounded)
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    placeholder(Icons.broken_image_outlined),
              ),
      ),
    );
  }
}

/// กลุ่มรายการตั้งค่าในการ์ดเดียว (ใช้ในหน้าโปรไฟล์/ตั้งค่า)
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children, this.title});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              title!.toUpperCase(),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.textMuted,
              ),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: appCardShadow,
          ),
          child: Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              side: const BorderSide(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const Divider(indent: 64),
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
