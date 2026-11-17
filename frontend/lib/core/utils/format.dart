import 'package:latlong2/latlong.dart';

import 'package:hopak_frontend/shared/widgets/dorm_map.dart' show mfuCenter;

/// ระยะจากมหาวิทยาลัยแม่ฟ้าหลวง เป็นกิโลเมตร ทศนิยม 1 ตำแหน่ง (เช่น "1.2")
String kmFromMfu(double latitude, double longitude) {
  final meters = const Distance().distance(
    mfuCenter,
    LatLng(latitude, longitude),
  );
  return (meters / 1000).toStringAsFixed(1);
}

/// เวลาในรายการแชท: วันนี้ = "HH:mm", เมื่อวาน = "Yesterday",
/// ภายใน 7 วัน = ชื่อวันย่อ (Mon), เก่ากว่านั้น = วัน/เดือน
String chatTime(String? raw, {DateTime? now}) {
  if (raw == null || raw.isEmpty) return '';
  final t = DateTime.tryParse(raw);
  if (t == null) return '';
  final local = t.toLocal();
  final today = now ?? DateTime.now();
  final d0 = DateTime(today.year, today.month, today.day);
  final days = d0.difference(DateTime(local.year, local.month, local.day)).inDays;
  if (days <= 0) return hhmm(local);
  if (days == 1) return 'Yesterday';
  if (days < 7) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[local.weekday - 1];
  }
  return '${local.day}/${local.month}';
}

/// "HH:mm" ของเวลาท้องถิ่น
String hhmm(DateTime local) =>
    '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';

/// แปลงเวลาจาก API เป็นข้อความสัมพัทธ์ เช่น "Today", "Yesterday", "3 days ago"
/// ถ้าอ่านเวลาไม่ได้ จะคืนข้อความเดิม
String relativeDay(String raw, {DateTime? now}) {
  final t = DateTime.tryParse(raw);
  if (t == null) return raw;
  final today = now ?? DateTime.now();
  final d0 = DateTime(today.year, today.month, today.day);
  final local = t.toLocal();
  final d1 = DateTime(local.year, local.month, local.day);
  final days = d0.difference(d1).inDays;
  if (days <= 0) return 'Today';
  if (days == 1) return 'Yesterday';
  if (days < 7) return '$days days ago';
  if (days < 14) return '1 week ago';
  if (days < 30) return '${days ~/ 7} weeks ago';
  return '${local.day}/${local.month}/${local.year}';
}

/// ระยะจากมหาวิทยาลัยแม่ฟ้าหลวงเป็นเมตร
double metersFromMfu(double latitude, double longitude) =>
    const Distance().distance(mfuCenter, LatLng(latitude, longitude));

/// ข้อความระยะทาง เช่น "850 ม." หรือ "1.2 กม."
String formatDistance(double meters) => meters < 1000
    ? '${meters.round()} ม.'
    : '${(meters / 1000).toStringAsFixed(1)} กม.';

/// ใส่ comma คั่นหลักพัน เช่น 3500 → "3,500"
String withCommas(int value) {
  final s = value.abs().toString();
  final out = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
    out.write(s[i]);
  }
  return out.toString();
}

/// ราคาต่อเดือน เช่น "3,500 บาท/เดือน"
String formatPrice(int pricePerMonth) => '${withCommas(pricePerMonth)} บาท/เดือน';

/// วันที่จาก API เป็น "วัน/เดือน/ปี" ถ้าอ่านไม่ได้คืนข้อความเดิม
String formatDate(String raw) {
  final t = DateTime.tryParse(raw);
  if (t == null) return raw;
  final l = t.toLocal();
  return '${l.day}/${l.month}/${l.year}';
}
