import 'package:shared_preferences/shared_preferences.dart';

/// เก็บ JWT ที่ได้จาก backend ไว้ในเครื่อง เพื่อให้ไม่ต้อง login ใหม่ทุกครั้ง
class TokenStore {
  static const _key = 'jwt_token';

  String? token;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_key);
  }

  Future<void> save(String value) async {
    token = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value);
  }

  Future<void> clear() async {
    token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
