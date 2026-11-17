import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/notifications/controllers/notifications_controller.dart';
import 'package:hopak_frontend/shared/models/notification.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:hopak_frontend/features/notifications/services/notification_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> _n(int id, {bool read = false}) => {
  'id': id,
  'type': 'approval',
  'title': 'แจ้ง $id',
  'body': null,
  'created_at': '2026-11-17T01:00:00.000Z',
  'read_at': read ? '2026-11-17T02:00:00.000Z' : null,
};

void main() {
  NotificationsController build(http.Client client) {
    final api = ApiClient(tokenProvider: () => 't', client: client);
    return NotificationsController(NotificationService(api));
  }

  test('load เก็บรายการและนับจำนวนที่ยังไม่อ่าน', () async {
    final c = build(
      MockClient(
        (req) async => _json({
          'notifications': [_n(1), _n(2, read: true), _n(3)],
        }),
      ),
    );
    expect(c.showFullLoader, isTrue);

    final ok = await c.load();

    expect(ok, isTrue);
    expect(c.items.length, 3);
    expect(c.unreadCount, 2);
    expect(c.loading, isFalse);
    expect(c.showFullLoader, isFalse);
  });

  test('load ล้มเหลวเก็บ error และคืน false', () async {
    final c = build(MockClient((req) async => _json({'message': 'x'}, 500)));
    final ok = await c.load();
    expect(ok, isFalse);
    expect(c.error, isA<ApiException>());
    expect(c.loading, isFalse);
  });

  test('open รายการที่ยังไม่อ่าน เรียก PATCH read แล้วโหลดใหม่', () async {
    final requests = <http.Request>[];
    var listed = 0;
    final c = build(
      MockClient((req) async {
        requests.add(req);
        if (req.method == 'PATCH') return _json({'message': 'ok'});
        listed++;
        // หลังอ่านแล้ว รายการที่ 1 เป็นอ่านแล้ว
        return _json({
          'notifications': [listed == 1 ? _n(1) : _n(1, read: true)],
        });
      }),
    );
    await c.load();
    final ok = await c.open(c.items.single);

    expect(ok, isTrue);
    final patch = requests.firstWhere((r) => r.method == 'PATCH');
    expect(patch.url.path, '/api/notifications/1/read');
    expect(c.unreadCount, 0);
  });

  test('open รายการที่อ่านแล้ว ไม่เรียก PATCH', () async {
    final requests = <http.Request>[];
    final c = build(
      MockClient((req) async {
        requests.add(req);
        return _json({
          'notifications': [_n(5, read: true)],
        });
      }),
    );
    await c.load();
    requests.clear();

    await c.open(c.items.single);

    expect(requests.where((r) => r.method == 'PATCH'), isEmpty);
    expect(requests.single.method, 'GET');
  });

  test('open ที่ทำเครื่องหมายอ่านไม่สำเร็จ คืน false และเก็บ error', () async {
    final c = build(
      MockClient((req) async {
        if (req.method == 'PATCH')
          return _json({'message': 'ไม่พบการแจ้งเตือน'}, 404);
        return _json({
          'notifications': [_n(9)],
        });
      }),
    );
    await c.load();

    final ok = await c.open(c.items.single);

    expect(ok, isFalse);
    expect(c.error, isA<ApiException>());
    expect(c.items.length, 1, reason: 'ยังโหลดรายการใหม่ได้');
  });

  test(
    'AppNotification.fromJson อ่านค่า read_at เป็น null เมื่อยังไม่อ่าน',
    () {
      expect(AppNotification.fromJson(_n(1)).isRead, isFalse);
      expect(AppNotification.fromJson(_n(1, read: true)).isRead, isTrue);
    },
  );
}
