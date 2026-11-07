import '../models/user.dart';
import 'api_client.dart';
import 'token_store.dart';

class AuthService {
  AuthService(this._api, this._tokens);

  final ApiClient _api;
  final TokenStore _tokens;

  /// POST /api/login { phone, password } → { token, user }
  /// แล้วเรียก GET /api/me เพื่อตรวจ role และสถานะ
  /// คืน null ถ้าเบอร์หรือรหัสผ่านไม่ถูกต้อง (401)
  /// โยน ApiException ถ้าบัญชีไม่ใช่ owner หรือถูกระงับ
  Future<CurrentUser?> login(String phone, String password) async {
    Object? data;
    try {
      data = await _api.post('/api/login', {
        'phone': phone,
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
    return CurrentUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// POST /api/auth/register { phone, password, confirmPassword }
  /// backend สร้างบัญชีเป็น student เสมอ
  Future<void> register(
    String phone,
    String password,
    String confirmPassword, {
    String? username,
  }) async {
    await _api.post('/api/auth/register', {
      'phone': phone,
      'password': password,
      'confirmPassword': confirmPassword,
      if (username != null && username.isNotEmpty) 'username': username,
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
