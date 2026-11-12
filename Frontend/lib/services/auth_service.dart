import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../mock/mock_db.dart';
import '../models/user.dart';

/// Auth (MOCK) – mirrors POST /auth/login, /auth/register, GET /auth/me ...
/// Login accepts username OR phone (users.username / users.phone).
class AuthService {
  final _db = MockDb.instance;
  static const _key = 'mock_user_id';
  static final _phoneRe = RegExp(r'^0[0-9]{8,9}$');

  Future<AppUser> login(String identifier, String password) async {
    await MockDb.delay();
    final id = identifier.trim();
    final u = _db.users.where((u) => u['phone'] == id || (u['username'] != null && u['username'] == id)).firstOrNull;
    if (u == null || _db.passwords[u['id']] != password) throw ApiException(401, 'ชื่อผู้ใช้/เบอร์โทร หรือรหัสผ่านไม่ถูกต้อง');
    if (u['status'] == 'suspended') throw ApiException(403, 'บัญชีนี้ถูกระงับ: ${u['suspension_reason'] ?? '-'}');
    return _save(u);
  }

  Future<AppUser> register({String? username, required String phone, required String password, required String role}) async {
    await MockDb.delay();
    final name = (username ?? '').trim();
    if (!['student', 'owner'].contains(role)) throw ApiException(400, 'role ต้องเป็น student หรือ owner');
    if (!_phoneRe.hasMatch(phone)) throw ApiException(400, 'เบอร์โทรต้องขึ้นต้นด้วย 0 และมี 9–10 หลัก');
    if (password.length < 8) throw ApiException(400, 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร');
    if (_db.users.any((u) => u['phone'] == phone)) throw ApiException(409, 'เบอร์โทรนี้ถูกใช้งานแล้ว');
    if (name.isNotEmpty && _db.users.any((u) => u['username'] == name)) throw ApiException(409, 'ชื่อผู้ใช้นี้ถูกใช้งานแล้ว');
    final u = {
      'id': _db.nextId('users'),
      'username': name.isEmpty ? null : name,
      'phone': phone,
      'role': role,
      'is_verified': 0,
      'status': 'active',
      'suspension_reason': null,
      'suspended_at': null,
      'suspended_by': null,
      'created_at': MockDb.now(),
      'updated_at': MockDb.now(),
    };
    _db.users.add(u);
    _db.passwords[u['id'] as int] = password;
    return _save(u);
  }

  Future<AppUser> me() async => AppUser.fromJson(_db.currentUser);

  Future<AppUser> updateProfile({String? username, required String phone}) async {
    await MockDb.delay(200);
    final u = _db.currentUser;
    final name = (username ?? '').trim();
    if (!_phoneRe.hasMatch(phone)) throw ApiException(400, 'เบอร์โทรต้องขึ้นต้นด้วย 0 และมี 9–10 หลัก');
    if (_db.users.any((x) => x['id'] != u['id'] && x['phone'] == phone)) throw ApiException(409, 'เบอร์โทรนี้ถูกใช้งานแล้ว');
    if (name.isNotEmpty && _db.users.any((x) => x['id'] != u['id'] && x['username'] == name)) {
      throw ApiException(409, 'ชื่อผู้ใช้นี้ถูกใช้งานแล้ว');
    }
    u
      ..['username'] = name.isEmpty ? null : name
      ..['phone'] = phone
      ..['updated_at'] = MockDb.now();
    return AppUser.fromJson(u);
  }

  Future<void> changePassword(String current, String next) async {
    await MockDb.delay(200);
    final id = _db.currentUser['id'] as int;
    if (_db.passwords[id] != current) throw ApiException(400, 'รหัสผ่านปัจจุบันไม่ถูกต้อง');
    if (next.length < 8) throw ApiException(400, 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร');
    _db.passwords[id] = next;
  }

  // ---------------- forgot password (verify with phone + OTP) ----------------
  // Mirrors: POST /auth/forgot-password {phone} → sends OTP by SMS
  //          POST /auth/verify-otp {phone, code} → reset_token
  //          POST /auth/reset-password {phone, reset_token, new_password}

  /// Step 1: send a 6-digit OTP to the phone. MOCK: returns the code so the UI can show it (no real SMS).
  Future<String> requestPasswordReset(String phone) async {
    await MockDb.delay(500);
    final p = phone.trim();
    if (!_phoneRe.hasMatch(p)) throw ApiException(400, 'เบอร์โทรต้องขึ้นต้นด้วย 0 และมี 9–10 หลัก');
    final u = _db.users.where((u) => u['phone'] == p).firstOrNull;
    if (u == null) throw ApiException(404, 'ไม่พบบัญชีที่ใช้เบอร์โทรนี้');
    if (u['status'] == 'suspended') throw ApiException(403, 'บัญชีนี้ถูกระงับ กรุณาติดต่อผู้ดูแลระบบ');
    final code = (100000 + Random().nextInt(900000)).toString();
    _db.passwordResets[p] = {
      'user_id': u['id'],
      'code': code,
      'expires_at': DateTime.now().add(const Duration(minutes: 5)),
      'attempts': 0,
      'reset_token': null,
    };
    return code;
  }

  /// Step 2: check the OTP (expires in 5 minutes, max 5 tries) → reset token
  Future<String> verifyResetOtp(String phone, String code) async {
    await MockDb.delay(400);
    final r = _db.passwordResets[phone.trim()];
    if (r == null) throw ApiException(400, 'กรุณาขอรหัส OTP ใหม่');
    if (DateTime.now().isAfter(r['expires_at'] as DateTime)) {
      _db.passwordResets.remove(phone.trim());
      throw ApiException(400, 'รหัส OTP หมดอายุแล้ว กรุณาขอรหัสใหม่');
    }
    if ((r['attempts'] as int) >= 5) throw ApiException(429, 'กรอกผิดเกินจำนวนครั้งที่กำหนด กรุณาขอรหัสใหม่');
    if (r['code'] != code.trim()) {
      r['attempts'] = (r['attempts'] as int) + 1;
      throw ApiException(400, 'รหัส OTP ไม่ถูกต้อง (เหลือ ${5 - (r['attempts'] as int)} ครั้ง)');
    }
    final token = 'reset-${r['user_id']}-${DateTime.now().millisecondsSinceEpoch}';
    r['reset_token'] = token;
    return token;
  }

  /// Step 3: set the new password
  Future<void> resetPassword(String phone, String resetToken, String newPassword) async {
    await MockDb.delay(400);
    final r = _db.passwordResets[phone.trim()];
    if (r == null || r['reset_token'] == null || r['reset_token'] != resetToken) {
      throw ApiException(400, 'ลิงก์รีเซ็ตไม่ถูกต้อง กรุณาเริ่มใหม่');
    }
    if (newPassword.length < 8) throw ApiException(400, 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร');
    _db.passwords[r['user_id'] as int] = newPassword;
    _db.passwordResets.remove(phone.trim());
  }

  Future<void> logout() async {
    _db.currentUserId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<AppUser?> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_key);
    final u = _db.userById(id);
    if (u == null || u['status'] != 'active') return null;
    _db.currentUserId = id;
    return AppUser.fromJson(u);
  }

  Future<AppUser> _save(Map<String, dynamic> u) async {
    _db.currentUserId = u['id'] as int;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, _db.currentUserId!);
    return AppUser.fromJson(u);
  }
}
