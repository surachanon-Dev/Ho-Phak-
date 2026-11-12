import 'package:intl/intl.dart';

final _num = NumberFormat('#,##0.##', 'en_US');

String formatBaht(num? v) => v == null ? '-' : '฿${_num.format(v)}';
String formatPrice(num? v) => v == null ? '-' : '${_num.format(v)} บาท/เดือน';

String formatDistance(num? meters) {
  if (meters == null) return '-';
  if (meters < 1000) return '${meters.round()} ม.';
  return '${(meters / 1000).toStringAsFixed(1)} กม.';
}

String formatDate(DateTime? d) => d == null ? '-' : DateFormat('dd/MM/yyyy').format(d.toLocal());
String formatDateTime(DateTime? d) => d == null ? '-' : DateFormat('dd/MM/yyyy HH:mm').format(d.toLocal());
String formatTime(DateTime? d) => d == null ? '' : DateFormat('HH:mm').format(d.toLocal());

/// water_billing_type / electricity_billing_type
const billingLabels = {
  'per_unit': 'ต่อหน่วย',
  'per_person_month': 'ต่อคน/เดือน',
  'per_room_month': 'ต่อห้อง/เดือน',
};

String formatRate(num? rate, String? type) {
  if (rate == null) return 'ไม่ระบุ';
  final unit = switch (type) {
    'per_unit' => 'บาท/หน่วย',
    'per_person_month' => 'บาท/คน/เดือน',
    'per_room_month' => 'บาท/ห้อง/เดือน',
    _ => 'บาท',
  };
  return '${_num.format(rate)} $unit';
}

/// dormitories.status
const dormStatusLabels = {
  'pending': 'รอตรวจสอบ',
  'published': 'เผยแพร่แล้ว',
  'rejected': 'ไม่อนุมัติ',
  'hidden': 'ซ่อนอยู่',
  'suspended': 'ถูกระงับ',
};

/// reviews.status
const reviewStatusLabels = {'pending': 'รอตรวจสอบ', 'published': 'เผยแพร่แล้ว', 'hidden': 'ซ่อนอยู่'};

/// generic approval labels
const approvalLabels = {'pending': 'รอตรวจสอบ', 'approved': 'อนุมัติแล้ว', 'rejected': 'ไม่อนุมัติ'};

/// users.status
const userStatusLabels = {'active': 'ใช้งาน', 'suspended': 'ถูกระงับ'};

const roleLabels = {'student': 'นักศึกษา', 'owner': 'เจ้าของหอพัก', 'admin': 'ผู้ดูแลระบบ'};

/// admin_logs.action
const adminActionLabels = {
  'dormitory.approve': 'อนุมัติหอพัก',
  'dormitory.reject': 'ไม่อนุมัติหอพัก',
  'dormitory.suspend': 'ระงับหอพัก',
  'dormitory.restore': 'คืนสถานะหอพัก',
  'user.suspend': 'ระงับผู้ใช้',
  'user.activate': 'เปิดใช้งานผู้ใช้',
};
