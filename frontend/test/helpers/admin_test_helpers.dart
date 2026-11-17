// ของที่ test ฝั่ง admin ใช้ร่วมกัน (ไฟล์นี้ไม่ใช่ test เพราะไม่ได้ลงท้ายด้วย _test.dart)
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/features/auth/services/auth_service.dart';
import 'package:hopak_frontend/core/network/token_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

typedef RequestHandler = Future<http.Response> Function(http.Request);

/// AppServices ปลอมที่มีแค่ api, tokens และ auth ส่วนอื่นจะ throw ถ้าถูกเรียก
class TestAppServices implements AppServices {
  TestAppServices(this.api, this.tokens) : auth = AuthService(api, tokens);

  @override
  final ApiClient api;

  @override
  final TokenStore tokens;

  @override
  final AuthService auth;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// ตอบ JSON กลับเหมือน backend จริง
http.Response jsonResponse(Object data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// สร้าง services ที่ทุก request วิ่งไปที่ [handler] แทน network จริง
TestAppServices servicesWith(RequestHandler handler) {
  final client = MockClient(handler);
  addTearDown(client.close);
  final tokens = TokenStore();
  return TestAppServices(
    ApiClient(tokenProvider: () => tokens.token, client: client),
    tokens,
  );
}

/// ตั้งขนาดจอจำลอง แล้วคืนค่าเดิมหลังจบ test
void setScreenSize(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

void setDesktopSize(WidgetTester tester) =>
    setScreenSize(tester, const Size(1920, 1080));

// ---------- ข้อมูลตัวอย่าง (fixture) ----------

const adminAccountFixture = {
  'user': {
    'id': 7,
    'username': 'Test Admin',
    'phone': '0800000000',
    'role': 'admin',
    'status': 'active',
    'is_verified': 1,
  },
};

const logFixture = {
  'id': 31,
  'action': 'review.hide',
  'admin_name': 'Test Admin',
  'target_type': 'review',
  'target_id': 9,
  'created_at': '2026-11-08T09:15:00Z',
};

const reviewFixture = {
  'id': 9,
  'dormitory_id': 26,
  'dormitory_name': 'Hillview Dorm',
  'rating': 2,
  'body': 'Test review for moderation',
  'author': 'Test Student',
  'created_at': '2026-11-08T09:10:00Z',
  'status': 'pending',
};

// ---------- ตรวจ layout บนจอมือถือ ----------

/// แถวตัวอย่างที่มีฟิลด์ที่หน้า admin ใช้ (ยาวพอให้ทดสอบข้อความยาว)
Map<String, dynamic> get _sampleRow => {
  'id': 1,
  'name': 'หอพักตัวอย่างชื่อยาวมากเพื่อทดสอบการตัดข้อความ',
  'username': 'owner_username_long_name',
  'first_name': 'สมชาย',
  'surname': 'ใจดีมากๆ',
  'phone': '0812345678',
  'owner_phone': '0812345678',
  'owner_username': 'owner_username_long_name',
  'owner_id': 1,
  'role': 'owner',
  'status': 'active',
  'zone': 'หน้ามอ',
  'is_verified': 1,
  'created_at': '2026-11-10T10:00:00.000Z',
  'submitted_at': '2026-11-10T10:00:00.000Z',
  'reviewed_at': null,
  'document_url': 'private_uploads/licence-long-file-name.png',
  'rejection_reason': 'เอกสารไม่ชัด',
  'dormitory_id': 1,
  'dormitory_name': 'หอพักตัวอย่าง',
  'rating': 4,
  'body': 'รีวิวตัวอย่างที่มีข้อความค่อนข้างยาวเพื่อดูการขึ้นบรรทัดใหม่บนหน้าจอเล็ก',
  'author': 'Anonymous123',
  'action': 'dormitory.approve',
  'admin_name': 'Admin',
  'target_type': 'dormitory',
  'target_id': 1,
  'status_reason': null,
  'price_per_month': 3000,
  'status_text': 'published',
};

/// ทุก endpoint ตอบรายการตัวอย่างเดียวกัน เพื่อให้หน้าแสดงข้อมูลจริง
http.Response _sampleResponse(http.Request req) {
  final rows = [_sampleRow];
  if (req.url.path == '/api/me') {
    return jsonResponse({
      'user': {..._sampleRow, 'role': 'admin'},
    });
  }
  return jsonResponse({
    'verifications': rows,
    'new_dormitories': rows,
    'revisions': rows,
    'dormitories': rows,
    'users': rows,
    'reviews': rows,
    'logs': rows,
    'amenities': rows,
    'queue': {'new_dormitories': rows, 'revisions': rows, 'verifications': rows},
  });
}

/// services ที่ทุก endpoint ตอบข้อมูลตัวอย่าง ใช้กับ test layout
TestAppServices sampleDataServices() {
  final client = MockClient((req) async => _sampleResponse(req));
  addTearDown(client.close);
  return TestAppServices(
    ApiClient(tokenProvider: () => 'admin-token', client: client),
    TokenStore(),
  );
}

/// pump หน้าที่ความกว้าง 360 พิกเซล (มือถือทั่วไป) แล้วตรวจว่าไม่มี overflow หรือ exception
Future<void> expectPhoneLayout(WidgetTester tester, Widget page) async {
  setScreenSize(tester, const Size(360, 740));

  await tester.pumpWidget(MaterialApp(home: Scaffold(body: page)));
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(tester.takeException(), isNull);
}
