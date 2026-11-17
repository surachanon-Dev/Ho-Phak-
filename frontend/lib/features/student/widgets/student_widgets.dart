import 'package:flutter/material.dart';

import 'package:hopak_frontend/core/theme/app_theme.dart';

// widget ย่อยที่ใช้ร่วมกันในหน้าของนักศึกษา (ปรับมาจาก views/widgets/common.dart ของ Frontend-Big)

/// สีดาวรีวิว
const kStarColor = Color(0xFFFFB300);

/// รูปจาก URL ถ้าไม่มีหรือโหลดไม่ได้จะแสดงกรอบไอคอนหอพักแทน
class NetImage extends StatelessWidget {
  const NetImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.radius = 12,
    this.fit = BoxFit.cover,
  });

  final String? url;
  final double? width;
  final double? height;
  final double radius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: AppColors.primarySoft,
      alignment: Alignment.center,
      child: const Icon(
        Icons.apartment_rounded,
        color: AppColors.primary,
        size: 36,
      ),
    );
    final src = url ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: src.isEmpty
          ? placeholder
          : Image.network(
              src,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (_, _, _) => placeholder,
            ),
    );
  }
}

/// หัวข้อของแต่ละส่วน มีปุ่มด้านขวาได้
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

/// คะแนนเฉลี่ย เช่น "★ 4.5 (12)" หรือ "ยังไม่มีรีวิว"
class RatingText extends StatelessWidget {
  const RatingText({super.key, this.rating, this.count});

  final double? rating;
  final int? count;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.star_rounded, color: kStarColor, size: 18),
      const SizedBox(width: 2),
      Text(
        rating == null
            ? 'ยังไม่มีรีวิว'
            : '${rating!.toStringAsFixed(1)} (${count ?? 0})',
        style: const TextStyle(fontSize: 13),
      ),
    ],
  );
}

/// ดาว 5 ดวงตามคะแนน
class Stars extends StatelessWidget {
  const Stars(this.rating, {super.key, this.size = 16});

  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 1; i <= 5; i++)
        Icon(
          i <= rating ? Icons.star_rounded : Icons.star_border_rounded,
          size: size,
          color: kStarColor,
        ),
    ],
  );
}

/// บรรทัดข้อมูลมีไอคอนนำหน้า
class InfoRow extends StatelessWidget {
  const InfoRow(this.icon, this.text, {super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

/// หน้าว่าง: ไอคอน ข้อความ คำอธิบาย และปุ่ม (ถ้ามี)
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.detail,
    this.action,
  });

  final IconData icon;
  final String message;
  final String? detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (detail != null) ...[
            const SizedBox(height: 4),
            Text(
              detail!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    ),
  );
}
