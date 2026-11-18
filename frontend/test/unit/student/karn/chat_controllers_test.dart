// ผู้รับผิดชอบ: Karn (นักศึกษา)
// ไฟล์นี้เป็นเทสต์ unit ของ controller ที่ระบุในชื่อ group
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/chat/chat_list/chat_list_controller.dart';
import 'package:hopak_frontend/features/chat/chat_room/chat_room_controller.dart';
import 'package:hopak_frontend/shared/models/chat.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:hopak_frontend/features/chat/services/chat_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> _conv(int id, String dorm) => {
  'id': id,
  'tenant_id': 20,
  'dormitory_name': dorm,
  'dormitory_status': 'published',
  'unread_count': 0,
  'last_message': 'สวัสดี',
  'last_sent_at': '2026-11-17T01:00:00.000Z',
};

Map<String, dynamic> _msg(int id, {String? readAt, String sentAt = '2026-11-17T01:00:00.000Z'}) => {
  'id': id,
  'sender_id': 20,
  'body': 'ข้อความ $id',
  'sent_at': sentAt,
  'read_at': readAt,
};

ChatService _chats(MockClient client) =>
    ChatService(ApiClient(tokenProvider: () => 't', client: client));

void main() {
  group('ChatListController', () {
    test('load เก็บรายการและแยกชื่อหอไม่ซ้ำ', () async {
      final c = ChatListController(_chats(MockClient((req) async => _json({
        'conversations': [_conv(1, 'หอ A'), _conv(2, 'หอ B'), _conv(3, 'หอ A')],
      }))));

      expect(await c.load(), isTrue);

      expect(c.items.length, 3);
      expect(c.dormNames, ['หอ A', 'หอ B']);
      expect(c.visible.length, 3);
      expect(c.loading, isFalse);
    });

    test('setDormFilter กรองรายการที่แสดง และชื่อที่ไม่มีจะเป็นทุกหอ', () async {
      final c = ChatListController(_chats(MockClient((req) async => _json({
        'conversations': [_conv(1, 'หอ A'), _conv(2, 'หอ B')],
      }))));
      await c.load();

      c.setDormFilter('หอ B');
      expect(c.visible.map((x) => x.id), [2]);

      c.setDormFilter('ไม่มีหอนี้');
      expect(c.dormFilter, isNull);
      expect(c.visible.length, 2);

      c.setDormFilter(null);
      expect(c.dormFilter, isNull);
    });

    test('ตัวกรองถูกล้างเมื่อหอนั้นหายจากรายการหลังโหลดใหม่', () async {
      var round = 0;
      final c = ChatListController(_chats(MockClient((req) async {
        round++;
        return _json({
          'conversations': round == 1
              ? [_conv(1, 'หอ A'), _conv(2, 'หอ B')]
              : [_conv(1, 'หอ A')],
        });
      })));
      await c.load();
      c.setDormFilter('หอ B');

      await c.load();

      expect(c.dormFilter, isNull);
    });

    test('delete สำเร็จ ลบออกจากรายการในเครื่อง', () async {
      final requests = <http.Request>[];
      final c = ChatListController(_chats(MockClient((req) async {
        requests.add(req);
        if (req.method == 'DELETE') return _json({'message': 'ok'});
        return _json({'conversations': [_conv(1, 'หอ A'), _conv(2, 'หอ B')]});
      })));
      await c.load();

      expect(await c.delete(2), isTrue);

      expect(c.items.map((x) => x.id), [1]);
      expect(requests.last.url.path, '/api/conversations/2');
      expect(requests.last.method, 'DELETE');
    });

    test('delete ไม่สำเร็จ เก็บ error และโหลดรายการใหม่', () async {
      var listCalls = 0;
      final c = ChatListController(_chats(MockClient((req) async {
        if (req.method == 'DELETE') return _json({'message': 'x'}, 500);
        listCalls++;
        return _json({'conversations': [_conv(1, 'หอ A')]});
      })));
      await c.load();

      expect(await c.delete(1), isFalse);
      expect(c.error, isA<ApiException>());
      expect(listCalls, 2, reason: 'โหลดใหม่หลังลบไม่สำเร็จ');
      expect(c.items.length, 1);
    });

    test('load ล้มเหลวคืน false และ loading เป็น false', () async {
      final c = ChatListController(_chats(MockClient((req) async => _json({'message': 'x'}, 500))));
      expect(await c.load(), isFalse);
      expect(c.loading, isFalse);
      expect(c.error, isNotNull);
    });
  });

  group('ChatRoomController', () {
    test('load เก็บข้อความและสถานะ read_only', () async {
      final c = ChatRoomController(
        conversationId: 7,
        chats: _chats(MockClient((req) async => _json({
          'messages': [_msg(1), _msg(2, readAt: '2026-11-17T02:00:00.000Z')],
          'read_only': true,
        }))),
      );

      expect(await c.load(), isTrue);

      expect(c.messages.length, 2);
      expect(c.readOnly, isTrue);
      expect(c.loading, isFalse);
    });

    test('send ตัดช่องว่างแล้วส่ง POST และโหลดข้อความใหม่', () async {
      final requests = <http.Request>[];
      final c = ChatRoomController(
        conversationId: 7,
        chats: _chats(MockClient((req) async {
          requests.add(req);
          if (req.method == 'POST') return _json({'id': 10}, 201);
          return _json({'messages': [_msg(10)], 'read_only': false});
        })),
      );

      final ok = await c.send('  สวัสดีครับ  ');

      expect(ok, isTrue);
      final post = requests.firstWhere((r) => r.method == 'POST');
      expect(post.url.path, '/api/conversations/7/messages');
      expect(jsonDecode(post.body), {'body': 'สวัสดีครับ'});
      expect(c.messages.length, 1, reason: 'โหลดข้อความใหม่หลังส่ง');
      expect(c.sending, isFalse);
    });

    test('send ข้อความว่างหรือมีแต่ช่องว่างไม่ยิง request', () async {
      final requests = <http.Request>[];
      final c = ChatRoomController(
        conversationId: 7,
        chats: _chats(MockClient((req) async {
          requests.add(req);
          return _json({'messages': [], 'read_only': false});
        })),
      );

      expect(await c.send(''), isFalse);
      expect(await c.send('    '), isFalse);
      expect(requests, isEmpty);
    });

    test('send ในห้องที่อ่านได้อย่างเดียวไม่ยิง request', () async {
      final requests = <http.Request>[];
      final c = ChatRoomController(
        conversationId: 7,
        chats: _chats(MockClient((req) async {
          requests.add(req);
          return _json({'messages': [], 'read_only': true});
        })),
      );
      await c.load();
      requests.clear();

      expect(await c.send('hello'), isFalse);
      expect(requests, isEmpty);
    });

    test('ข้อความยาวเกิน 2000 ตัวให้ validationError และไม่ยิง request', () async {
      final requests = <http.Request>[];
      final c = ChatRoomController(
        conversationId: 7,
        chats: _chats(MockClient((req) async {
          requests.add(req);
          return _json({'messages': [], 'read_only': false});
        })),
      );

      final ok = await c.send('ก' * (ChatRoomController.maxMessageLength + 1));

      expect(ok, isFalse);
      expect(c.validationError, isNotNull);
      expect(requests, isEmpty);
    });

    test('ข้อความยาวพอดี 2000 ตัวส่งได้', () async {
      final requests = <http.Request>[];
      final c = ChatRoomController(
        conversationId: 7,
        chats: _chats(MockClient((req) async {
          requests.add(req);
          if (req.method == 'POST') return _json({'id': 1}, 201);
          return _json({'messages': [], 'read_only': false});
        })),
      );

      final ok = await c.send('a' * ChatRoomController.maxMessageLength);

      expect(ok, isTrue);
      expect(c.validationError, isNull);
    });

    test('send ล้มเหลวเก็บ error และ sending กลับเป็น false', () async {
      final c = ChatRoomController(
        conversationId: 7,
        chats: _chats(MockClient((req) async {
          if (req.method == 'POST') return _json({'message': 'หอถูกระงับ'}, 403);
          return _json({'messages': [], 'read_only': false});
        })),
      );

      final ok = await c.send('hi');

      expect(ok, isFalse);
      expect(c.error, isA<ApiException>());
      expect(c.sending, isFalse);
    });

    test('stampFor แสดง Read เฉพาะข้อความของเราที่อีกฝ่ายอ่านแล้ว', () {
      final read = ChatMessage.fromJson(_msg(1, readAt: '2026-11-17T02:00:00.000Z'));
      final unread = ChatMessage.fromJson(_msg(2));

      expect(ChatRoomController.stampFor(read, mine: true), contains('Read'));
      expect(ChatRoomController.stampFor(unread, mine: true), isNot(contains('Read')));
      expect(ChatRoomController.stampFor(read, mine: false), isNot(contains('Read')));
    });

    test('stampFor ว่างเมื่ออ่านเวลาไม่ได้', () {
      final bad = ChatMessage.fromJson(_msg(3, sentAt: 'not-a-date'));
      expect(ChatRoomController.stampFor(bad, mine: false), '');
      expect(ChatRoomController.dayOf(bad), isNull);
    });

    test('dayOf ตัดเวลาเหลือแค่วัน', () {
      final m = ChatMessage.fromJson(_msg(4, sentAt: '2026-11-17T10:30:00.000Z'));
      final day = ChatRoomController.dayOf(m)!;
      expect(day.hour, 0);
      expect(day.minute, 0);
    });
  });
}
