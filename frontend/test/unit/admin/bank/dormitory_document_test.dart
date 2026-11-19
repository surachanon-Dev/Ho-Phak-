// ผู้รับผิดชอบ: Bank (แอดมิน)
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/owner/services/api_owner_extras.dart';
import 'package:hopak_frontend/features/admin/services/admin_service.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hopak_frontend/features/owner/models/dorm_document.dart';

void main() {
  test('แอดมินดึงเอกสารความเป็นเจ้าของหอด้วย GET /api/admin/dormitories/:id/document', () async {
    final log = <http.Request>[];
    final api = ApiClient(
      tokenProvider: () => 'admin-token',
      client: MockClient((req) async {
        log.add(req);
        return http.Response.bytes([1, 2, 3], 200);
      }),
    );

    final bytes = await AdminService(api).dormitoryDocument(16);

    expect(bytes, Uint8List.fromList([1, 2, 3]));
    expect(log.single.method, 'GET');
    expect(log.single.url.path, '/api/admin/dormitories/16/document');
    expect(log.single.headers['authorization'], 'Bearer admin-token');
  });

  test('เจ้าของอัปโหลดเอกสารหอแบบ multipart ช่อง document พร้อมชนิดไฟล์', () async {
    String? body;
    final api = ApiClient(
      tokenProvider: () => 'owner-token',
      client: MockClient.streaming((req, stream) async {
        body = utf8.decode(await stream.toBytes(), allowMalformed: true);
        expect(req.url.path, '/api/owner/dormitories/7/document');
        return http.StreamedResponse(
          Stream.value(utf8.encode(jsonEncode({'message': 'ok'}))),
          201,
        );
      }),
    );

    await ApiOwnerExtras(api).saveDormDocument(
      7,
      DormDocument(name: 'deed.pdf', sizeBytes: 3, bytes: Uint8List.fromList([1, 2, 3])),
    );

    expect(body!.toLowerCase(), contains('name="document"; filename="deed.pdf"'));
    expect(body!.toLowerCase(), contains('content-type: application/pdf'));
  });

  test('ไม่มีไฟล์ใหม่ (bytes เป็น null) ไม่ส่ง request', () async {
    var calls = 0;
    final api = ApiClient(
      tokenProvider: () => 't',
      client: MockClient.streaming((req, stream) async {
        calls++;
        return http.StreamedResponse(Stream.value(utf8.encode('{}')), 200);
      }),
    );

    await ApiOwnerExtras(api).saveDormDocument(7, const DormDocument(name: 'old.pdf', sizeBytes: 9));
    await ApiOwnerExtras(api).saveDormDocument(7, null);

    expect(calls, 0);
  });
}
