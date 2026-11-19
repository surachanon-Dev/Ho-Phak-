import '../model/user.dart';
import '../core/network/api_client.dart';
import '../core/network/token_store.dart';

class AuthService {
  AuthService(this._api, this._tokens);

  final ApiClient _api;
  final TokenStore _tokens;

  /// id ผู้ใช้ล่าสุดจาก GET /api/me (ใช้เป็นกุญแจข้อมูลที่เก็บในเครื่อง)
  int? userId;

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
      throw ApiException(
        403,
        'This account is suspended. Please contact an admin.',
      );
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

  /// POST /api/me/become-owner: นักศึกษาสมัครเป็นเจ้าของหอ (ต้องยืนยันตัวตนต่อ)
  /// แล้วโหลดข้อมูลผู้ใช้ใหม่ (role = owner, is_verified = false)
  Future<CurrentUser> becomeOwner() async {
    await _api.post('/api/me/become-owner', const {});
    return currentUser();
  }

  /// POST /api/auth/register { phone, password, confirmPassword }
  /// backend สร้างบัญชีเป็น student เสมอ
  Future<void> register(
    String phone,
    String password,
    String confirmPassword, {
    String? firstName,
    String? surname,
  }) async {
    await _api.post('/api/auth/register', {
      'phone': phone,
      'password': password,
      'confirmPassword': confirmPassword,
      if (firstName != null && firstName.isNotEmpty) 'first_name': firstName,
      if (surname != null && surname.isNotEmpty) 'surname': surname,
    });
  }

  /// GET /api/support-contact → { phone }
  Future<String?> supportContactPhone() async {
    try {
      final data = await _api.get('/api/support-contact') as Map<String, dynamic>;
      final phone = (data['phone'] as String?)?.trim();
      return (phone == null || phone.isEmpty) ? null : phone;
    } catch (_) {
      return null;
    }
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
