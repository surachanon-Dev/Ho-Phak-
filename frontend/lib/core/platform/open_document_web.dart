// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

/// เปิด PDF ในแท็บใหม่ผ่านตัวดู PDF ของเบราว์เซอร์ คืน true เมื่อเปิดได้
bool openPdfInNewTab(Uint8List bytes) {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  return true;
}
