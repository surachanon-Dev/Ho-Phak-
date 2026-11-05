import '../models/dormitory_details.dart';

class OwnerContact {
  const OwnerContact({this.email = '', this.phone = ''});

  final String email;
  final String phone;
}

/// ข้อมูลของผู้ใช้ที่ล็อกอินอยู่และรายละเอียดหอ เก็บในหน่วยความจำ (ปิดแอปแล้วหาย)
abstract final class OwnerSession {
  static String username = '';
  static final Map<String, OwnerContact> _contacts = {};

  /// รายละเอียดตัวอย่างของหอสองหลังแรก เพื่อให้เห็นหน้าตาตอนสถานะต่างกัน
  static final Map<int, DormitoryDetails> _details = {
    1: const DormitoryDetails(
      status: DormitoryStatus.approved,
      published: true,
      availableRooms: 4,
      waterRate: 18,
      electricRate: 8,
      deposit: 3000,
      address: '99 หมู่ 10 ต.ท่าสุด อ.เมือง จ.เชียงราย',
      description: 'ห้องกว้าง เงียบสงบ เดินไปมหาวิทยาลัยไม่เกิน 10 นาที',
      amenities: {'Wi-Fi', 'แอร์', 'ที่จอดรถ', 'กล้องวงจรปิด'},
    ),
    2: const DormitoryDetails(
      status: DormitoryStatus.rejected,
      rejectReason: 'ภาพถ่ายหอไม่ชัดเจน',
      availableRooms: 0,
      waterRate: 150,
      waterBilling: WaterBilling.flat,
      electricRate: 7,
      deposit: 2500,
    ),
  };

  static OwnerContact get contact => _contacts[username] ?? const OwnerContact();

  static void saveContact(String user, {required String email, required String phone}) {
    _contacts[user] = OwnerContact(email: email, phone: phone);
  }

  static DormitoryDetails detailsOf(int dormitoryId) => _details[dormitoryId] ?? const DormitoryDetails();

  static void saveDetails(int dormitoryId, DormitoryDetails details) => _details[dormitoryId] = details;

  static void removeDetails(int dormitoryId) => _details.remove(dormitoryId);
}
