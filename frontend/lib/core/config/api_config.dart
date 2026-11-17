class ApiConfig {
  /// เปลี่ยนได้ตอนรันโดยไม่ต้องแก้โค้ด เช่น Android emulator:
  /// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// แปลง path รูป/ไฟล์ที่ backend ส่งมา (เช่น uploads/x.png) ให้เป็น URL เต็ม
  static String resolve(String pathOrUrl) {
    if (pathOrUrl.startsWith('http')) return pathOrUrl;
    final path = pathOrUrl.startsWith('/') ? pathOrUrl : '/$pathOrUrl';
    return '$baseUrl$path';
  }
}
