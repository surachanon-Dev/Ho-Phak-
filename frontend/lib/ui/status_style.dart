import 'package:flutter/material.dart';

import '../models/dormitory.dart';

/// สีของชิปสถานะหอพัก (พื้นสีอ่อน + ตัวอักษรเข้ม ตาม Figma; Suspended เป็นพื้นเข้ม)
({Color bg, Color fg}) statusStyle(String status) => switch (status) {
  DormStatus.published => (
    bg: const Color(0xFFDDF5E3),
    fg: const Color(0xFF1B6B33),
  ),
  DormStatus.pending => (
    bg: const Color(0xFFFFF0C2),
    fg: const Color(0xFF8A5A00),
  ),
  DormStatus.changesPending => (
    bg: const Color(0xFFE9E1FB),
    fg: const Color(0xFF5B34B1),
  ),
  DormStatus.rejected => (
    bg: const Color(0xFFFCE0E0),
    fg: const Color(0xFFB3261E),
  ),
  DormStatus.suspended => (bg: const Color(0xFFB3261E), fg: Colors.white),
  _ => (bg: const Color(0xFFE6E8EC), fg: const Color(0xFF4B5563)), // hidden
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
