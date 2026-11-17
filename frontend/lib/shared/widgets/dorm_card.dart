import 'package:flutter/material.dart';

import 'package:hopak_frontend/shared/models/dormitory.dart';
import 'package:hopak_frontend/core/theme/app_theme.dart';
import 'package:hopak_frontend/core/utils/format.dart';
import 'package:hopak_frontend/features/student/widgets/student_widgets.dart';

/// การ์ดหอพักฝั่งนักศึกษา (แนวนอน ตามดีไซน์ของ Frontend-Big):
/// รูป ชื่อ ราคา โซน · ระยะจากมหาวิทยาลัย ห้องว่าง และคะแนนรีวิว
/// รายการค้นหาของ backend ยังไม่ส่งรูปมา จึงแสดงกรอบรูปว่างแทน
class DormCard extends StatelessWidget {
  const DormCard({
    super.key,
    required this.dorm,
    required this.onTap,
    this.trailing,
  });

  final Dormitory dorm;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final d = dorm;
    final full = d.availableRooms <= 0;
    final distance = formatDistance(metersFromMfu(d.latitude, d.longitude));
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NetImage(d.coverUrl, width: 96, height: 96),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            d.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (trailing != null) trailing!,
                      ],
                    ),
                    Text(
                      formatPrice(d.pricePerMonth),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${d.zone} · $distance',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        RatingText(rating: d.ratingAvg, count: d.reviewCount),
                        const Spacer(),
                        Text(
                          full ? 'เต็ม' : 'ว่าง ${d.availableRooms} ห้อง',
                          style: TextStyle(
                            fontSize: 12,
                            color: full ? AppColors.danger : AppColors.textMuted,
                          ),
                        ),
                      ],
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
}
