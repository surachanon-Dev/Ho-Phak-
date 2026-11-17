import 'owner_extras.dart';

/// บัญชีของ owner: โปรไฟล์, เปลี่ยนรหัสผ่าน, ตั้งค่าแจ้งเตือน
/// ทุกอย่างเดินผ่าน [OwnerExtras] (local หรือ API ตาม kLocalOwnerExtras)
/// หน้าจอ owner เรียกผ่านคลาสนี้ ไม่แตะ OwnerExtras ตรงๆ
class OwnerAccountController {
  OwnerAccountController(this._extras);

  final OwnerExtras _extras;

  /// true = โหมดเก็บในเครื่อง (backend ยังไม่มี endpoint)
  bool get isLocal => _extras.isLocal;

  Future<OwnerProfile> profile({String? fallbackName}) =>
      _extras.profile(fallbackName: fallbackName);

  /// photoBase64: null = คงเดิม, '' = ลบ · เบอร์ใหม่ต้องใส่รหัสผ่านและรอ admin อนุมัติ
  Future<OwnerProfile> saveProfile({
    required String firstName,
    required String surname,
    required String phone,
    String? password,
    String? photoBase64,
  }) => _extras.saveProfile(
    firstName: firstName,
    surname: surname,
    phone: phone,
    password: password,
    photoBase64: photoBase64,
  );

  Future<void> changePassword({
    required String current,
    required String next,
  }) => _extras.changePassword(current: current, next: next);

  Future<NotificationPrefs> notificationPrefs() => _extras.notificationPrefs();

  Future<void> saveNotificationPrefs(NotificationPrefs prefs) =>
      _extras.saveNotificationPrefs(prefs);
}
