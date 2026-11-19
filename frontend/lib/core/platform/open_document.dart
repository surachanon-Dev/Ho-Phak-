// เปิดไฟล์เอกสาร (PDF) ในแท็บใหม่ของเบราว์เซอร์
// บนเว็บใช้ dart:html ส่วนที่รันบน VM (เทสต์) ใช้ stub ที่คืน false
export 'open_document_stub.dart'
    if (dart.library.html) 'open_document_web.dart';
