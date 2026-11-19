// ผู้รับผิดชอบ: ส่วนกลาง (ทุกคนใช้ร่วมกัน)
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('contentTypeFor', () {
    test('แปลงนามสกุลเป็นชนิดไฟล์ที่เซิร์ฟเวอร์รับ', () {
      expect(contentTypeFor('003.jpg').toString(), 'image/jpeg');
      expect(contentTypeFor('SCAN.JPEG').toString(), 'image/jpeg');
      expect(contentTypeFor('a.png').toString(), 'image/png');
      expect(contentTypeFor('a.webp').toString(), 'image/webp');
      expect(contentTypeFor('doc.pdf').toString(), 'application/pdf');
      expect(contentTypeFor('noext').toString(), 'application/octet-stream');
    });
  });

  test('uploadFiles ส่ง part ของเอกสารพร้อม Content-Type ของรูป', () async {
    String? body;
    final api = ApiClient(
      tokenProvider: () => 'token',
      client: MockClient.streaming((req, stream) async {
        body = utf8.decode(await stream.toBytes(), allowMalformed: true);
        return http.StreamedResponse(
          Stream.value(utf8.encode(jsonEncode({'message': 'ok'}))),
          201,
        );
      }),
    );

    await api.uploadFiles(
      '/api/owner/verification',
      fieldName: 'document',
      files: [UploadFile(bytes: Uint8List.fromList([1, 2, 3]), filename: '003.jpg')],
    );

    expect(body, contains('name="document"; filename="003.jpg"'));
    expect(body!.toLowerCase(), contains('content-type: image/jpeg'));
    expect(body!.toLowerCase(), isNot(contains('application/octet-stream')));
  });
}
