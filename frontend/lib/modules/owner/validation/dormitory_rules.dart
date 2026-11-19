/// กติกาของฟอร์มหอพัก (ไม่ผูกกับ UI) — validator คืนข้อความ error หรือ null ถ้าผ่าน
/// ข้อความและเงื่อนไขย้ายมาจาก dormitory_form_screen.dart ตรงๆ ไม่เปลี่ยนพฤติกรรม
class DormitoryRules {
  const DormitoryRules._();

  /// รูปต่อหอสูงสุด / ต่อการเลือกหนึ่งครั้ง / ขนาดต่อรูป
  static const maxImages = 10;
  static const maxImagesPerPick = 5;
  static const maxImageBytes = 5 * 1024 * 1024;

  /// เอกสารหอ (pdf/jpg/png) ขนาดสูงสุด
  static const maxDocumentBytes = 10 * 1024 * 1024;
  static const documentExtensions = ['pdf', 'jpg', 'jpeg', 'png'];

  /// จำนวนรูปที่เลือกเพิ่มได้ในครั้งนี้ เมื่อมีรูปอยู่แล้ว [current] รูป
  static int pickLimit(int current) {
    final remaining = maxImages - current;
    return remaining > maxImagesPerPick ? maxImagesPerPick : remaining;
  }

  static String? required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This field is required' : null;

  static String? price(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null) return 'Enter a whole number';
    if (n < 1 || n > 1000000)
      return 'Price must be between 1 and 1,000,000 THB';
    return null;
  }

  static String? totalRooms(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null) return 'Enter a whole number';
    return n < 0 ? 'Rooms cannot be negative' : null;
  }

  /// [totalText] = ข้อความในช่อง total rooms (ใช้เทียบว่าห้องว่างไม่เกินห้องทั้งหมด)
  static String? availableRooms(String? v, String totalText) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null) return 'Enter a whole number';
    final total = int.tryParse(totalText.trim());
    if (n < 0) return 'Available rooms cannot be negative';
    if (total != null && n > total) {
      return 'Available rooms cannot exceed total rooms';
    }
    return null;
  }

  static String? rate(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    final n = double.tryParse(t);
    if (n == null) return 'Enter a number';
    return n < 0 ? 'Cannot be negative' : null;
  }

  static String? rateRequired(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Enter the rate';
    return rate(v);
  }

  /// กรอกอัตราแล้วต้องเลือกวิธีคิดเงินด้วย
  static String? billing(String? v, String rateText) {
    if (rateText.trim().isNotEmpty && v == null) {
      return 'Choose how it is billed';
    }
    return null;
  }
}
