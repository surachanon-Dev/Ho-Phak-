/// 3200 -> 3,200  /  12.5 -> 12.5
String withCommas(num value) {
  final isWhole = value == value.roundToDouble();
  final parts = (isWhole ? value.toInt().toString() : value.toString()).split('.');
  final integer = parts.first.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return parts.length > 1 ? '$integer.${parts[1]}' : integer;
}

/// 0812345678 -> 081-234-5678 (ไม่ครบ 10 หลักคืนค่าเดิม)
String phoneWithDashes(String phone) {
  if (phone.length != 10 || int.tryParse(phone) == null) return phone;
  return '${phone.substring(0, 3)}-${phone.substring(3, 6)}-${phone.substring(6)}';
}

/// อักษรแรกของชื่อ ใช้เป็นรูปโปรไฟล์
String firstLetter(String name) =>
    name.isEmpty ? '?' : String.fromCharCode(name.runes.first).toUpperCase();
