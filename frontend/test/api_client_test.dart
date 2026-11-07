import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/models/dormitory.dart';
import 'package:hopak_frontend/services/api_client.dart';
import 'package:hopak_frontend/services/auth_service.dart';
import 'package:hopak_frontend/services/dormitory_service.dart';
import 'package:hopak_frontend/services/token_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test(
    'Dormitory.fromJson แปลง DECIMAL ที่เป็น string และรูปจาก file_path',
    () {
      final d = Dormitory.fromJson({
        'id': 1,
        'name': 'หอ A',
        'zone': 'หน้ามอ',
        'latitude': '19.0323000',
        'longitude': '99.8972000',
        'price_per_month': 3500,
        'total_rooms': 10,
        'available_rooms': 4,
        'water_rate': '18.00',
        'water_billing_type': 'per_unit',
        'electricity_rate': null,
        'electricity_billing_type': null,
        'status': 'published',
        'images': [
          {'id': 9, 'file_path': 'uploads/a.png', 'sort_order': 0},
        ],
      });
      expect(d.latitude, closeTo(19.0323, 1e-9));
      expect(d.longitude, closeTo(99.8972, 1e-9));
      expect(d.pricePerMonth, 3500);
      expect(d.waterRate, 18.0);
      expect(d.electricityRate, isNull);
      expect(d.images.single.fullUrl, 'http://localhost:3000/uploads/a.png');
    },
  );

  test('canToggleVisibility ใช้ได้เฉพาะ published และ hidden', () {
    Dormitory make(String status) => Dormitory(
      id: 1,
      name: 'x',
      zone: 'หน้ามอ',
      latitude: 0,
      longitude: 0,
      pricePerMonth: 1,
      totalRooms: 0,
      availableRooms: 0,
      status: status,
    );

    expect(make(DormStatus.published).canToggleVisibility, isTrue);
    expect(make(DormStatus.hidden).canToggleVisibility, isTrue);
    expect(make(DormStatus.pending).canToggleVisibility, isFalse);
    expect(make(DormStatus.changesPending).canToggleVisibility, isFalse);
    expect(make(DormStatus.suspended).canEdit, isFalse);
  });

  test('login คืน user เมื่อ role เป็น owner และเก็บ token', () async {
    final tokens = TokenStore();
    final mock = MockClient((req) async {
      switch (req.url.path) {
        case '/api/login':
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          expect(body['phone'], '0812345678');
          return _json({
            'message': 'Login success',
            'token': 'tok',
            'user': {'id': 5, 'role': 'owner', 'is_verified': 1},
          });
        case '/api/me':
          expect(req.headers['Authorization'], 'Bearer tok');
          return _json({
            'user': {
              'id': 5,
              'username': 'owner1',
              'role': 'owner',
              'status': 'active',
              'is_verified': 1,
            },
          });
      }
      return _json({'message': 'ok'});
    });
    final auth = AuthService(
      ApiClient(tokenProvider: () => tokens.token, client: mock),
      tokens,
    );

    final user = await auth.login('0812345678', 'password123');
    expect(user, isNotNull);
    expect(user!.isOwner, isTrue);
    expect(user.isVerified, isTrue);
    expect(tokens.token, 'tok');
  });

  test('login รหัสผิดคืน null และไม่เก็บ token', () async {
    final tokens = TokenStore();
    final mock = MockClient(
      (req) async => http.Response('Password not match', 401),
    );
    final auth = AuthService(
      ApiClient(tokenProvider: () => tokens.token, client: mock),
      tokens,
    );
    expect(await auth.login('0812345678', 'wrong'), isNull);
    expect(tokens.token, isNull);
  });

  test('login ของ student สำเร็จและเก็บ token (ใช้โครงนักศึกษา)', () async {
    final tokens = TokenStore();
    final mock = MockClient((req) async {
      if (req.url.path == '/api/login') {
        return _json({'message': 'Login success', 'token': 'tok'});
      }
      if (req.url.path == '/api/me') {
        return _json({
          'user': {
            'id': 2,
            'role': 'student',
            'status': 'active',
            'is_verified': 0,
          },
        });
      }
      return _json({'message': 'ok'});
    });
    final auth = AuthService(
      ApiClient(tokenProvider: () => tokens.token, client: mock),
      tokens,
    );
    final user = await auth.login('0812345678', 'password123');
    expect(user, isNotNull);
    expect(user!.isStudent, isTrue);
    expect(tokens.token, 'tok');
  });

  test('login ของ admin สำเร็จและเก็บ token (แอดมินใช้แอปนี้ได้)', () async {
    final tokens = TokenStore();
    final mock = MockClient((req) async {
      if (req.url.path == '/api/login') {
        return _json({'message': 'Login success', 'token': 'tok'});
      }
      if (req.url.path == '/api/me') {
        return _json({
          'user': {
            'id': 3,
            'role': 'admin',
            'status': 'active',
            'is_verified': 1,
          },
        });
      }
      return _json({'message': 'ok'});
    });
    final auth = AuthService(
      ApiClient(tokenProvider: () => tokens.token, client: mock),
      tokens,
    );
    final user = await auth.login('0812345678', 'password123');
    expect(user!.isAdmin, isTrue);
    expect(tokens.token, 'tok');
  });

  test('create ส่ง total_rooms และไม่ส่งค่าน้ำเมื่อไม่ได้กรอกอัตรา', () async {
    final tokens = TokenStore()..token = 'secret-token';
    late http.Request captured;
    final mock = MockClient((req) async {
      captured = req;
      return _json({'message': 'เพิ่มหอพักสำเร็จ', 'id': 7}, 201);
    });
    final id =
        await DormitoryService(
          ApiClient(tokenProvider: () => tokens.token, client: mock),
        ).create(
          DormitoryInput(
            name: 'หอ B',
            zone: 'คชพลแลนด์',
            latitude: 19.03,
            longitude: 99.89,
            pricePerMonth: 4000,
            totalRooms: 10,
            availableRooms: 3,
          ),
        );

    expect(id, 7);
    expect(captured.headers['Authorization'], 'Bearer secret-token');
    final sent = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(sent['total_rooms'], 10);
    expect(sent['available_rooms'], 3);
    expect(sent.containsKey('water_rate'), isFalse);
    expect(sent.containsKey('water_billing_type'), isFalse);
    expect(sent['amenity_ids'], isEmpty);
  });

  test('create ส่งค่าน้ำเป็นคู่เมื่อกรอกอัตรา', () async {
    final tokens = TokenStore()..token = 't';
    late http.Request captured;
    final mock = MockClient((req) async {
      captured = req;
      return _json({'id': 1}, 201);
    });
    await DormitoryService(
      ApiClient(tokenProvider: () => tokens.token, client: mock),
    ).create(
      DormitoryInput(
        name: 'หอ C',
        zone: 'หน้ามอ',
        latitude: 19,
        longitude: 99,
        pricePerMonth: 3000,
        totalRooms: 5,
        availableRooms: 5,
        waterRate: 18,
        waterBillingType: BillingType.perUnit,
      ),
    );
    final sent = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(sent['water_rate'], 18);
    expect(sent['water_billing_type'], 'per_unit');
  });

  test('toggleVisibility คืนสถานะใหม่จาก PATCH', () async {
    final tokens = TokenStore()..token = 't';
    late http.Request captured;
    final mock = MockClient((req) async {
      captured = req;
      return _json({'status': 'hidden'});
    });
    final status = await DormitoryService(
      ApiClient(tokenProvider: () => tokens.token, client: mock),
    ).toggleVisibility(3);
    expect(status, 'hidden');
    expect(captured.method, 'PATCH');
    expect(captured.url.path, '/api/owner/dormitories/3/visibility');
  });

  test('server ต่อไม่ได้ ให้ ApiException statusCode 0', () async {
    final mock = MockClient(
      (req) async => throw http.ClientException('refused'),
    );
    final api = ApiClient(tokenProvider: () => null, client: mock);
    await expectLater(
      DormitoryService(api).list(),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 0)),
    );
  });
}
