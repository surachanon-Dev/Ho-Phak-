class ApiConfig {
  // Windows / Chrome / Edge ใช้ localhost ได้เลย
  // Android emulator ต้องเปลี่ยนเป็น http://10.0.2.2:3000
  static const String baseUrl = 'http://localhost:3000';

  /// แปลง path รูป/ไฟล์ที่ backend ส่งมา (เช่น uploads/x.png) ให้เป็น URL เต็ม
  static String resolve(String pathOrUrl) {
    if (pathOrUrl.startsWith('http')) return pathOrUrl;
    final path = pathOrUrl.startsWith('/') ? pathOrUrl : '/$pathOrUrl';
    return '$baseUrl$path';
  }
}
