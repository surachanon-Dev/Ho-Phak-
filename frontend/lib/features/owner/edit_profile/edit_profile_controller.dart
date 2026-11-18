import 'package:flutter/foundation.dart';

import 'package:hopak_frontend/features/owner/validation/owner_account_rules.dart';
import 'package:hopak_frontend/features/owner/services/owner_account_service.dart';
import 'package:hopak_frontend/features/owner/models/owner_profile.dart';

/// หน้าแก้โปรไฟล์: เก็บค่าที่กำลังแก้ คำนวณว่ามีการเปลี่ยนแปลงหรือไม่ ตรวจฟอร์ม และบันทึก
class EditProfileController extends ChangeNotifier {
  EditProfileController({
    required this.original,
    required OwnerAccountService account,
  }) : _account = account,
       _firstName = original.firstName,
       _surname = original.surname,
       _phone = original.phone,
       _photo = original.photoBase64;

  /// โปรไฟล์ก่อนแก้ (ใช้เทียบว่ามีการเปลี่ยนแปลงหรือไม่)
  final OwnerProfile original;
  final OwnerAccountService _account;

  String _firstName;
  String _surname;
  String _phone;
  String _password = '';
  String? _photo;
  bool _photoChanged = false;
  bool _saving = false;
  Object? _error;
  OwnerProfile? _saved;

  String get firstName => _firstName;
  String get surname => _surname;
  String get phone => _phone;
  String? get photo => _photo;
  bool get photoChanged => _photoChanged;
  bool get saving => _saving;
  Object? get error => _error;

  /// โปรไฟล์ที่บันทึกสำเร็จแล้ว (null = ยังไม่ได้บันทึก)
  OwnerProfile? get saved => _saved;

  void setFirstName(String v) => _set(() => _firstName = v);
  void setSurname(String v) => _set(() => _surname = v);
  void setPhone(String v) => _set(() => _phone = v);
  void setPassword(String v) => _set(() => _password = v);

  /// เลือกรูปใหม่ (base64) ส่ง null = ลบรูป (บันทึกเป็นค่าว่าง)
  void setPhoto(String? base64) => _set(() {
    _photo = base64;
    _photoChanged = true;
  });

  void _set(VoidCallback change) {
    change();
    notifyListeners();
  }

  /// เปลี่ยนเบอร์จากเดิม (ต้องมีเบอร์เดิมอยู่ด้วย)
  bool get phoneChanged =>
      original.phone.isNotEmpty && _phone.trim() != original.phone;

  /// มีการเปลี่ยนแปลงอย่างน้อยหนึ่งอย่าง
  bool get dirty =>
      _photoChanged ||
      _firstName.trim() != original.firstName ||
      _surname.trim() != original.surname ||
      _phone.trim() != original.phone;

  /// กดบันทึกได้เมื่อมีการเปลี่ยนแปลงและไม่ได้กำลังบันทึกอยู่
  /// (ฟอร์มที่ไม่ผ่านยังกดได้เพื่อให้หน้าจอแสดงข้อความ error ของช่องนั้น ๆ)
  bool get canSave => dirty && !_saving;

  String? validateFirstName() =>
      _firstName.trim().isEmpty ? 'Enter your first name' : null;

  String? validateSurname() =>
      _surname.trim().isEmpty ? 'Enter your surname' : null;

  String? validatePhone() => OwnerAccountRules.phone(_phone);

  String? validatePassword() => OwnerAccountRules.passwordForPhoneChange(
    _password,
    phoneChanged: phoneChanged,
  );

  /// ฟอร์มทั้งหมดผ่านหรือไม่
  bool get isValid =>
      validateFirstName() == null &&
      validateSurname() == null &&
      validatePhone() == null &&
      validatePassword() == null;

  /// บันทึก คืน true เมื่อสำเร็จ (ดูค่าที่บันทึกใน [saved])
  Future<bool> save() async {
    if (!canSave || !isValid) {
      notifyListeners();
      return false;
    }
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      _saved = await _account.saveProfile(
        firstName: _firstName.trim(),
        surname: _surname.trim(),
        phone: _phone.trim(),
        password: _password,
        photoBase64: _photoChanged ? (_photo ?? '') : null,
      );
      return true;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}
