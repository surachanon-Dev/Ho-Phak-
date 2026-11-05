import '../models/dormitory.dart';
import 'owner_session.dart';

class OwnerException implements Exception {
  final int statusCode;
  final String message;

  OwnerException(this.statusCode, this.message);

  @override
  String toString() => message;
}

// ข้อมูลและการล็อกอินของ owner เก็บในหน่วยความจำเท่านั้น (ยังไม่เชื่อม backend)
// ปิดแอปแล้วข้อมูลกลับเป็นค่าเริ่มต้น เมื่อมี backend ให้เปลี่ยนเนื้อในฟังก์ชันเหล่านี้เป็นการเรียก API
// ชื่อและรูปแบบฟังก์ชันคงไว้ให้ตรงกับ endpoint ของ backend เพื่อให้หน้าจอไม่ต้องแก้
class OwnerController {
  // บัญชีตัวอย่างสำหรับลองใช้ (username / password)
  static final Map<String, String> _users = {'owner_test1': 'password123'};
  static String? _session;

  static final List<Dormitory> _dormitories = [
    Dormitory(id: 1, name: 'บ้านสวนลำดวน', zone: 'หลังมอ', latitude: 20.0430, longitude: 99.8960, pricePerMonth: 3200),
    Dormitory(id: 2, name: 'หอพักนภา', zone: 'คชพลแลนด์', latitude: 20.0475, longitude: 99.8905, pricePerMonth: 2500),
  ];
  static int _nextId = 3;

  // ---- session ----
  static Future<String?> getToken() async => _session;

  static Future<void> clearToken() async => _session = null;

  // ---- Auth ----
  static Future<void> register(String username, String password) async {
    if (_users.containsKey(username)) {
      throw OwnerException(409, 'username นี้ถูกใช้แล้ว');
    }
    if (password.length < 8) {
      throw OwnerException(400, 'password ต้องยาวอย่างน้อย 8 ตัว');
    }
    _users[username] = password;
  }

  static Future<void> login(String username, String password) async {
    if (!_users.containsKey(username)) throw OwnerException(401, 'ไม่พบชื่อผู้ใช้นี้');
    if (_users[username] != password) throw OwnerException(401, 'รหัสผ่านไม่ถูกต้อง');
    _session = username;
    OwnerSession.username = username;
  }

  static Future<void> logout() async {
    _session = null;
    OwnerSession.username = '';
  }

  // ตอนนี้ไม่มีขั้นตอนตรวจว่ายืนยันตัวตนแล้วหรือยัง จึงผ่านเสมอ
  static Future<void> checkOwner() async {}

  // ---- Dormitory ----
  static Future<List<Dormitory>> fetchDormitories() async => List.unmodifiable(_dormitories);

  // คืน id ของหอที่เพิ่งสร้าง เพื่อใช้เก็บข้อมูลเสริมของหอนั้น
  static Future<int?> createDormitory(Map<String, dynamic> body) async {
    final id = _nextId++;
    _dormitories.add(_fromBody(id, body));
    return id;
  }

  static Future<void> updateDormitory(int id, Map<String, dynamic> body) async {
    final index = _dormitories.indexWhere((d) => d.id == id);
    if (index < 0) throw OwnerException(404, 'ไม่พบหอพัก');
    _dormitories[index] = _fromBody(id, body);
  }

  static Future<void> deleteDormitory(int id) async {
    _dormitories.removeWhere((d) => d.id == id);
  }

  static Dormitory _fromBody(int id, Map<String, dynamic> body) => Dormitory(
        id: id,
        name: body['name'] as String,
        zone: body['zone'] as String,
        latitude: (body['latitude'] as num).toDouble(),
        longitude: (body['longitude'] as num).toDouble(),
        pricePerMonth: body['price_per_month'] as int,
      );
}
