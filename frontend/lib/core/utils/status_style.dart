import 'package:flutter/material.dart';

import '../../shared/models/dormitory.dart';

/// สีของชิปสถานะหอพัก (พื้นสีอ่อน + ตัวอักษรเข้ม; Suspended เป็นพื้นเข้ม)
({Color bg, Color fg}) statusStyle(String status) => switch (status) {
  DormStatus.published => (
    bg: const Color(0xFFE7F8F1),
    fg: const Color(0xFF047857),
  ),
  DormStatus.pending => (
    bg: const Color(0xFFFFF6E5),
    fg: const Color(0xFFB45309),
  ),
  DormStatus.changesPending => (
    bg: const Color(0xFFF1EBFE),
    fg: const Color(0xFF6D28D9),
  ),
  DormStatus.rejected => (
    bg: const Color(0xFFFDECEC),
    fg: const Color(0xFFB91C1C),
  ),
  DormStatus.suspended => (bg: const Color(0xFFDC2626), fg: Colors.white),
  _ => (bg: const Color(0xFFEFF1F5), fg: const Color(0xFF475569)), // hidden
};

/// สีเดียวสำหรับข้อความ/ไอคอนที่อิงสถานะ
Color statusColor(String status) => statusStyle(status).fg;

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.displayStatus});

  final String displayStatus;

  @override
  Widget build(BuildContext context) {
    final style = statusStyle(displayStatus);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        DormStatus.label(displayStatus),
        style: TextStyle(
          color: style.fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
