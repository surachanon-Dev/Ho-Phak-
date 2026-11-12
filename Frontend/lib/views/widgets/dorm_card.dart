import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/dormitory.dart';
import 'common.dart';

/// Dorm list card used by every role
class DormCard extends StatelessWidget {
  const DormCard({super.key, required this.dorm, this.onTap, this.trailing, this.showStatus = false});
  final Dormitory dorm;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final d = dorm;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NetImage(d.coverImage, width: 96, height: 96),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(d.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navy)),
                      ),
                      if (trailing != null) trailing!,
                    ]),
                    Text(formatPrice(d.pricePerMonth), style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('${d.zone} · ${formatDistance(d.distanceMeters)}',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    const SizedBox(height: 4),
                    Row(children: [
                      RatingText(rating: d.avgRating, count: d.reviewCount),
                      const Spacer(),
                      if (showStatus) StatusChip(d.status),
                    ]),
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
