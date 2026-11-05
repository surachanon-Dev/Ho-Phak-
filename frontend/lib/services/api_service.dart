import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/dormitory.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiService {
  static const _tokenKey = 'token';

  // ---- token ----
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ---- ส่ง request แล้วแปลงผลลัพธ์ ----
  // ถ้า status ไม่ใช่ 2xx จะ throw ApiException พร้อมข้อความจาก backend
  static Future<Map<String, dynamic>> _send(Future<http.Response> Function() request) async {
    final res = await request();

    // backend บางจุดส่งข้อความธรรมดาแทน JSON จึงต้องดักไว้
    Map<String, dynamic> data = {};
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }
    final message = data['message'] as String? ?? res.body;
    throw ApiException(res.statusCode, message);
  }

  // ---- Auth ----
  static Future<void> register(String username, String password) async {
    await _send(() => http.post(
          Uri.parse('$apiBaseUrl/api/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}),
        ));
  }

  static Future<void> login(String username, String password) async {
    final data = await _send(() => http.post(
          Uri.parse('$apiBaseUrl/api/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}),
        ));
    await _saveToken(data['token'] as String);
  }

  static Future<void> logout() async {
    // ลบ token ฝั่งแอปเสมอ ไม่ว่า server จะตอบอะไร
    try {
      await _send(() async => http.post(
            Uri.parse('$apiBaseUrl/api/auth/logout'),
            headers: await _authHeaders(),
          ));
    } catch (_) {}
    await clearToken();
  }

  // เช็กว่าเป็น owner ที่ยืนยันตัวตนแล้วหรือยัง (ใช้หลัง login)
  static Future<void> checkOwner() async {
    await _send(() async => http.get(
          Uri.parse('$apiBaseUrl/api/owner/middleware'),
          headers: await _authHeaders(),
        ));
  }

  // ---- Dormitory ----
  static Future<List<Dormitory>> fetchDormitories() async {
    final data = await _send(() async => http.get(
          Uri.parse('$apiBaseUrl/api/owner/dormitories'),
          headers: await _authHeaders(),
        ));
    final list = data['dormitories'] as List<dynamic>;
    return list.map((e) => Dormitory.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> createDormitory(Map<String, dynamic> body) async {
    await _send(() async => http.post(
          Uri.parse('$apiBaseUrl/api/owner/dormitories'),
          headers: await _authHeaders(),
          body: jsonEncode(body),
        ));
  }

  static Future<void> updateDormitory(int id, Map<String, dynamic> body) async {
    await _send(() async => http.put(
          Uri.parse('$apiBaseUrl/api/owner/dormitories/$id'),
          headers: await _authHeaders(),
          body: jsonEncode(body),
        ));
  }

  static Future<void> deleteDormitory(int id) async {
    await _send(() async => http.delete(
          Uri.parse('$apiBaseUrl/api/owner/dormitories/$id'),
          headers: await _authHeaders(),
        ));
  }
}
