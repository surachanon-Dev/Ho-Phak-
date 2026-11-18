import 'dart:typed_data';

/// เอกสารกรรมสิทธิ์ของหอ (ชื่อไฟล์ + ขนาด)
class DormDocument {
  const DormDocument({required this.name, required this.sizeBytes, this.bytes});

  final String name;
  final int sizeBytes;

  /// เนื้อไฟล์ที่เลือกในฟอร์ม (ใช้อัปโหลดตอนบันทึก) เป็น null เมื่อโหลดจากที่เก็บในเครื่อง
  final Uint8List? bytes;

  Map<String, dynamic> toJson() => {'name': name, 'size': sizeBytes};

  factory DormDocument.fromJson(Map<String, dynamic> json) => DormDocument(
    name: json['name'] as String,
    sizeBytes: (json['size'] as num).toInt(),
  );
}
