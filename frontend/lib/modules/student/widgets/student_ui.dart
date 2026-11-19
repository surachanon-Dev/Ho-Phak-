import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';

/// ความกว้างสูงสุดของเนื้อหาหน้า student (อ่านง่ายบนจอกว้าง)
const double kStudentContentWidth = 760;

/// สีดาวรีวิว
const kStarColor = Color(0xFFF59E0B);

/// ห่อเนื้อหาให้กว้างไม่เกิน [kStudentContentWidth] และอยู่กลางจอ
class StudentBody extends StatelessWidget {
  const StudentBody({super.key, required this.child, this.maxWidth});

  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    // สูงเท่าเนื้อหา ไม่ขยายเต็มพื้นที่ (เช่น ตอนอยู่ใน bottomNavigationBar)
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? kStudentContentWidth),
      child: child,
    ),
  );
}

/// ราคาต่อเดือน เช่น "3,500 บาท/เดือน" (ตัวเลขเด่น หน่วยจาง)
class PriceText extends StatelessWidget {
  const PriceText(this.pricePerMonth, {super.key, this.size = 16});

  final int pricePerMonth;
  final double size;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: withCommas(pricePerMonth),
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        TextSpan(
          text: ' baht/month',
          style: TextStyle(
            fontSize: size * 0.75,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
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
      const Icon(Icons.star_rounded, color: kStarColor, size: 17),
      const SizedBox(width: 2),
      Text(
        rating == null
            ? 'No reviews yet'
            : '${rating!.toStringAsFixed(1)} (${count ?? 0})',
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: rating == null ? FontWeight.w500 : FontWeight.w700,
          color: rating == null ? AppColors.textMuted : AppColors.textBody,
        ),
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

/// หัวหน้าไล่สีอินดิโก้ (แบบเดียวกับ My Dorms ของ owner) วางบนสุดของหน้า
class StudentHero extends StatelessWidget {
  const StudentHero({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.child,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  /// เนื้อหาเพิ่มใต้หัวข้อ เช่น ช่องค้นหา
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: const [
          BoxShadow(
            color: Color(0x334F46E5),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: Colors.white,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xD9FFFFFF),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          if (child != null) ...[const SizedBox(height: 16), child!],
        ],
      ),
    );
  }
}

/// ปุ่มไอคอนวงกลมสีขาวโปร่ง ใช้บนหัวหน้าไล่สี (แชท / แจ้งเตือน)
class HeroIconButton extends StatelessWidget {
  const HeroIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.count = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  /// จำนวนที่ยังไม่อ่าน (0 = ไม่แสดงตัวเลข)
  final int count;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    style: IconButton.styleFrom(
      backgroundColor: const Color(0x26FFFFFF),
      foregroundColor: Colors.white,
    ),
    icon: Badge(
      isLabelVisible: count > 0,
      label: Text(count > 99 ? '99+' : '$count'),
      child: Icon(icon, size: 20),
    ),
  );
}
