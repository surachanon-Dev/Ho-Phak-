import 'package:flutter/foundation.dart';

import '../../services/auth_service.dart';
import 'owner_account_controller.dart';
import 'owner_account_rules.dart';
import 'owner_extras.dart';

/// หน้า "โปรไฟล์" ของ owner: โหลดโปรไฟล์ (มี fallback เป็นชื่อผู้ใช้) และออกจากระบบ
class OwnerProfileController extends ChangeNotifier {
  OwnerProfileController({
    required OwnerAccountController account,
    required AuthService auth,
    required this.fallbackName,
  }) : _account = account,
       _auth = auth;

  final OwnerAccountController _account;
  final AuthService _auth;

  /// ชื่อที่ใช้แทนเมื่อโหลดโปรไฟล์ไม่ได้ (มาจาก username)
  final String? fallbackName;

  OwnerProfile _profile = const OwnerProfile();
  bool _loading = false;
  Object? _error;

  OwnerProfile get profile => _profile;
  bool get loading => _loading;

  /// error ของการโหลดโปรไฟล์ (การโหลดล้มเหลวไม่ได้ทำให้หน้าพัง จึงเก็บไว้เฉย ๆ)
  Object? get error => _error;

  Future<bool> load() async {
    _loading = true;
    notifyListeners();
    try {
      _profile = await _account.profile(fallbackName: fallbackName);
      _error = null;
      return true;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// ออกจากระบบ (ลบ token ในเครื่องเสมอ)
  Future<void> logout() => _auth.logout();
}

/// หน้าแก้โปรไฟล์: เก็บค่าที่กำลังแก้ คำนวณว่ามีการเปลี่ยนแปลงหรือไม่ ตรวจฟอร์ม และบันทึก
class EditProfileController extends ChangeNotifier {
  EditProfileController({
    required this.original,
    required OwnerAccountController account,
  }) : _account = account,
       _firstName = original.firstName,
       _surname = original.surname,
       _phone = original.phone,
       _photo = original.photoBase64;

  /// โปรไฟล์ก่อนแก้ (ใช้เทียบว่ามีการเปลี่ยนแปลงหรือไม่)
  final OwnerProfile original;
  final OwnerAccountController _account;

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

/// หน้าเปลี่ยนรหัสผ่าน: ตรวจกติกาด้วย [OwnerAccountRules] และส่งคำขอ
class ChangePasswordController extends ChangeNotifier {
  ChangePasswordController(this._account);

  final OwnerAccountController _account;

  String _current = '';
  String _next = '';
  String _confirm = '';
  bool _saving = false;
  Object? _error;

  bool get saving => _saving;
  Object? get error => _error;

  void setCurrent(String v) => _set(() => _current = v);
  void setNext(String v) => _set(() => _next = v);
  void setConfirm(String v) => _set(() => _confirm = v);

  void _set(VoidCallback change) {
    change();
    notifyListeners();
  }

  String? validateCurrent() => OwnerAccountRules.currentPassword(_current);
  String? validateNext() => OwnerAccountRules.newPassword(_next, current: _current);
  String? validateConfirm() => OwnerAccountRules.confirmPassword(_confirm, next: _next);

  bool get isValid =>
      validateCurrent() == null && validateNext() == null && validateConfirm() == null;

  /// คืน true เมื่อเปลี่ยนรหัสผ่านสำเร็จ
  Future<bool> submit() async {
    if (_saving || !isValid) {
      notifyListeners();
      return false;
    }
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      await _account.changePassword(current: _current, next: _next);
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

/// หน้าตั้งค่าแจ้งเตือน: โหลดค่า สลับสวิตช์ และย้อนค่ากลับถ้าบันทึกไม่สำเร็จ
class NotificationSettingsController extends ChangeNotifier {
  NotificationSettingsController(this._account);

  final OwnerAccountController _account;

  NotificationPrefs? _prefs;
  Object? _error;

  NotificationPrefs? get prefs => _prefs;
  Object? get error => _error;

  Future<bool> load() async {
    try {
      _prefs = await _account.notificationPrefs();
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e;
      notifyListeners();
      return false;
    }
  }

  /// ตั้งค่าใหม่ทันที (แสดงผลทันที) ถ้าบันทึกไม่สำเร็จจะย้อนกลับเป็นค่าเดิม
  Future<bool> update(NotificationPrefs next) async {
    final before = _prefs;
    _prefs = next;
    _error = null;
    notifyListeners();
    try {
      await _account.saveNotificationPrefs(next);
      return true;
    } catch (e) {
      _prefs = before;
      _error = e;
      notifyListeners();
      return false;
    }
  }
}
