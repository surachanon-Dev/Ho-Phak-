import 'package:flutter/material.dart';

import '../models/dormitory.dart';
import '../ui/app_theme.dart';

/// การ์ดหอพักฝั่งนักศึกษา: ชื่อ โซน ราคา ห้องว่าง และคะแนนรีวิว
/// backend ยังไม่ส่งรูปในรายการ จึงแสดงกรอบรูปว่างไว้ก่อน
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
    final full = dorm.availableRooms <= 0;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 96,
              width: double.infinity,
              color: AppColors.primarySoft,
              alignment: Alignment.center,
              child: const Icon(
                Icons.apartment_outlined,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dorm.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dorm.zone,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${dorm.pricePerMonth} บาท/เดือน',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          full ? 'เต็ม' : 'ว่าง ${dorm.availableRooms} ห้อง',
                          style: TextStyle(
                            fontSize: 12,
                            color: full
                                ? AppColors.danger
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                      if (dorm.ratingAvg != null)
                        Text(
                          '★ ${dorm.ratingAvg!.toStringAsFixed(1)}'
                          ' (${dorm.reviewCount ?? 0})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.warningText,
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
    );
  }
}
