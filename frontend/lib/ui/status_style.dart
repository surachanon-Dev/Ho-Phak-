import 'package:flutter/material.dart';

import '../models/dormitory.dart';

/// สีของชิปสถานะหอพัก
Color statusColor(String status) => switch (status) {
  DormStatus.published => Colors.green.shade700,
  DormStatus.pending || DormStatus.changesPending => Colors.amber.shade800,
  DormStatus.rejected => Colors.red.shade700,
  DormStatus.suspended => Colors.red.shade900,
  _ => Colors.blueGrey.shade600, // hidden
};

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.displayStatus});

  final String displayStatus;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(displayStatus);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        DormStatus.label(displayStatus),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
