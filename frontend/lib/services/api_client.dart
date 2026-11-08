import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// ข้อผิดพลาดจาก API ที่แสดงให้ผู้ใช้เห็นได้โดยตรง
class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  /// 0 = เชื่อมต่อเซิร์ฟเวอร์ไม่ได้
  final int statusCode;
  final String message;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// ไฟล์ที่จะอัปโหลด (จาก file picker หรือ image picker)
class UploadFile {
  UploadFile({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}

class ApiClient {
  ApiClient({required this.tokenProvider, http.Client? client})
    : _client = client ?? http.Client();

  final String? Function() tokenProvider;
  final http.Client _client;

  static const _timeout = Duration(seconds: 15);

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Map<String, String> _headers({bool json = true}) {
    final token = tokenProvider();
    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String path) =>
      _send(() => _client.get(_uri(path), headers: _headers(json: false)));

  Future<dynamic> post(String path, Map<String, dynamic> body) => _send(
    () => _client.post(_uri(path), headers: _headers(), body: jsonEncode(body)),
  );

  Future<dynamic> put(String path, Map<String, dynamic> body) => _send(
    () => _client.put(_uri(path), headers: _headers(), body: jsonEncode(body)),
  );

  Future<dynamic> patch(String path, Map<String, dynamic> body) => _send(
    () =>
        _client.patch(_uri(path), headers: _headers(), body: jsonEncode(body)),
  );

  Future<dynamic> delete(String path) =>
      _send(() => _client.delete(_uri(path), headers: _headers(json: false)));

  /// อัปโหลดไฟล์แบบ multipart (ใช้กับรูปหอพัก)
  Future<dynamic> uploadFiles(
    String path, {
    required String fieldName,
    required List<UploadFile> files,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path))
      ..headers.addAll(_headers(json: false))
      ..files.addAll(
        files.map(
          (f) => http.MultipartFile.fromBytes(
            fieldName,
            f.bytes,
            filename: f.filename,
          ),
        ),
      );
    try {
      final streamed = await request.send().timeout(_timeout);
      final res = await http.Response.fromStream(streamed);
      return _decode(res);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw _networkError();
    }
  }

  /// ดึงไฟล์ดิบ (เช่น เอกสารยืนยันตัวตนของแอดมิน) พร้อมต้องแนบ token
  Future<Uint8List> getBytes(String path) async {
    final http.Response res;
    try {
      res = await _client
          .get(_uri(path), headers: _headers(json: false))
          .timeout(_timeout);
    } catch (_) {
      throw _networkError();
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return res.bodyBytes;
    _decode(res); // จะโยน ApiException พร้อมข้อความจาก server
    throw ApiException(res.statusCode, 'ดาวน์โหลดไม่สำเร็จ');
  }

  Future<dynamic> _send(Future<http.Response> Function() call) async {
    final http.Response res;
    try {
      res = await call().timeout(_timeout);
    } catch (_) {
      throw _networkError();
    }
    return _decode(res);
  }

  ApiException _networkError() => ApiException(
    0,
    'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ ตรวจสอบว่า backend รันอยู่ที่ ${ApiConfig.baseUrl}',
  );

  dynamic _decode(http.Response res) {
    dynamic data;
    if (res.bodyBytes.isNotEmpty) {
      final text = utf8.decode(res.bodyBytes);
      try {
        data = jsonDecode(text);
      } catch (_) {
        // backend บางเส้นส่งข้อความธรรมดากลับมา (เช่น 'User not found')
        data = text;
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }

    var message = 'เกิดข้อผิดพลาด (รหัส ${res.statusCode})';
    if (data is Map && data['message'] is String) {
      message = data['message'] as String;
    } else if (data is String && data.trim().isNotEmpty) {
      message = data.trim();
    }
    throw ApiException(res.statusCode, message);
  }
}
