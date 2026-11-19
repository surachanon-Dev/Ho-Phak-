import 'package:flutter/material.dart';

import '../model/dormitory.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/format.dart';
import '../modules/owner/widgets/owner_ui.dart' show DormCover;
import '../modules/student/widgets/student_ui.dart';
import 'ui/ui.dart';

/// การ์ดหอพักฝั่งนักศึกษา (ธีมโครงใหม่): รูป ชื่อ โซน · ระยะจากมหาวิทยาลัย
/// ราคา ป้ายห้องว่าง และคะแนนรีวิว
/// รายการค้นหาของ backend ยังไม่ส่งรูปมา จึงแสดงกรอบรูปไล่สีแทน
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
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DormCover(url: d.coverUrl, width: 96, height: 96),
          const SizedBox(width: 14),
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
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    ?trailing,
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 14,
                      color: AppColors.textFaint,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        '${zoneLabel(d.zone)} · $distance',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                PriceText(d.pricePerMonth),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ToneBadge(
                      label: full ? 'Full' : '${d.availableRooms} rooms free',
                      tone: full ? Tone.danger : Tone.success,
                      icon: full
                          ? Icons.block_rounded
                          : Icons.meeting_room_outlined,
                    ),
                    const Spacer(),
                    RatingText(rating: d.ratingAvg, count: d.reviewCount),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
