import 'package:hopak_frontend/shared/models/user.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:hopak_frontend/core/network/token_store.dart';

class AuthService {
  AuthService(this._api, this._tokens);

  final ApiClient _api;
  final TokenStore _tokens;

  /// id ผู้ใช้ล่าสุดจาก GET /api/me (ใช้เป็นกุญแจข้อมูลที่เก็บในเครื่อง)
  int? userId;

  /// true ถ้าค่าที่กรอกเป็นเบอร์โทร (0xxxxxxxxx หรือ +66xxxxxxxxx เว้นวรรค/ขีดได้)
  static bool looksLikePhone(String value) =>
      RegExp(r'^(\+66|0)\d{8,9}$').hasMatch(value.replaceAll(RegExp(r'[\s-]'), ''));

  /// POST /api/login { phone, password } หรือ { username, password } → { token, user }
  /// ถ้ากรอกเป็นเบอร์จะส่ง phone ถ้าไม่ใช่เบอร์จะส่ง username
  /// แล้วเรียก GET /api/me เพื่อตรวจ role และสถานะ
  /// คืน null ถ้าชื่อผู้ใช้/เบอร์ หรือรหัสผ่านไม่ถูกต้อง (401)
  Future<CurrentUser?> login(String phoneOrUsername, String password) async {
    Object? data;
    try {
      data = await _api.post('/api/login', {
        if (looksLikePhone(phoneOrUsername))
          'phone': phoneOrUsername
        else
          'username': phoneOrUsername,
        'password': password,
      });
    } on ApiException catch (e) {
      if (e.statusCode == 401) return null;
      rethrow;
    }

    await _tokens.save((data as Map<String, dynamic>)['token'] as String);

    final user = await currentUser();
    if (user.isSuspended) {
      await logout();
      throw ApiException(403, 'บัญชีนี้ถูกระงับ ติดต่อแอดมิน');
    }
    return user;
  }

  /// GET /api/me → { user: { id, username, role, status, is_verified } }
  Future<CurrentUser> currentUser() async {
    final data = await _api.get('/api/me') as Map<String, dynamic>;
    final user = CurrentUser.fromJson(data['user'] as Map<String, dynamic>);
    userId = user.id;
    return user;
  }

  /// POST /api/auth/register { phone, password, confirmPassword, username?, role }
  /// role: 'student' หรือ 'owner' (backend ต้องรองรับการรับ role ด้วย)
  Future<void> register(
    String phone,
    String password,
    String confirmPassword, {
    String? username,
    String? firstName,
    String? surname,
    String? role,
  }) async {
    await _api.post('/api/auth/register', {
      'phone': phone,
      'password': password,
      'confirmPassword': confirmPassword,
      if (username != null && username.isNotEmpty) 'username': username,
      if (firstName != null && firstName.isNotEmpty) 'first_name': firstName,
      if (surname != null && surname.isNotEmpty) 'surname': surname,
      if (role != null) 'role': role,
    });
  }

  /// POST /api/auth/logout แล้วลบ token ฝั่ง client เสมอ
  Future<void> logout() async {
    try {
      await _api.post('/api/auth/logout', const {});
    } catch (_) {
      // ไม่ว่าเรียกสำเร็จหรือไม่ ก็ต้องลบ token ในเครื่อง
    }
    await _tokens.clear();
  }
}
