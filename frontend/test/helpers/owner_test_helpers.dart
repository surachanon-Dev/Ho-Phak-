// ของที่ widget test ฝั่ง owner ใช้ร่วมกัน (ไม่ใช่ test เพราะไม่ได้ลงท้ายด้วย _test.dart)
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:hopak_frontend/core/network/token_store.dart';
import 'package:hopak_frontend/features/auth/services/auth_service.dart';
import 'package:hopak_frontend/features/chat/services/chat_service.dart';
import 'package:hopak_frontend/features/notifications/services/notification_service.dart';
import 'package:hopak_frontend/features/owner/services/dormitory_service.dart';
import 'package:hopak_frontend/features/owner/services/local_owner_extras.dart';
import 'package:hopak_frontend/features/owner/services/owner_account_service.dart';
import 'package:hopak_frontend/features/owner/services/owner_extras.dart';
import 'package:hopak_frontend/features/owner/services/verification_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'admin_test_helpers.dart' show jsonResponse;

export 'admin_test_helpers.dart' show jsonResponse;

/// AppServices ปลอมของฝั่ง owner: ใช้ service จริงทั้งหมด แต่ทุก request วิ่งไป MockClient
/// และข้อมูลเสริมของ owner เก็บในเครื่อง (LocalOwnerExtras) ส่วนที่ไม่ได้ใช้จะ throw ถ้าถูกเรียก
class OwnerTestServices implements AppServices {
  OwnerTestServices(this.api, this.tokens) : auth = AuthService(api, tokens) {
    extras = LocalOwnerExtras(userId: () => auth.userId);
    dormitories = DormitoryService(api, extras);
    account = OwnerAccountService(extras);
    verification = VerificationService(api);
    chats = ChatService(api);
    notifications = NotificationService(api);
  }

  @override
  final ApiClient api;

  @override
  final TokenStore tokens;

  @override
  final AuthService auth;

  @override
  late final OwnerExtras extras;

  @override
  late final DormitoryService dormitories;

  @override
  late final OwnerAccountService account;

  @override
  late final VerificationService verification;

  @override
  late final ChatService chats;

  @override
  late final NotificationService notifications;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// สร้าง services ที่ทุก request วิ่งไปที่ [handler] แทน network จริง
OwnerTestServices ownerServicesWith(
  Future<http.Response> Function(http.Request) handler,
) {
  final client = MockClient(handler);
  addTearDown(client.close);
  final tokens = TokenStore();
  return OwnerTestServices(
    ApiClient(tokenProvider: () => tokens.token, client: client),
    tokens,
  );
}

// ---------- ข้อมูลตัวอย่าง (fixture) ----------

Map<String, dynamic> dormJson({
  int id = 1,
  String name = 'Baan Suan',
  String status = 'published',
  int price = 3200,
  int total = 10,
  int available = 4,
}) => {
  'id': id,
  'name': name,
  'zone': 'หน้ามอ',
  'latitude': '19.9500',
  'longitude': '99.8900',
  'price_per_month': price,
  'total_rooms': total,
  'available_rooms': available,
  'status': status,
  'description': 'Quiet dorm near campus',
  'address': '1 Moo 1',
  'contact_phone': '0812345678',
  'amenity_ids': <int>[],
  'images': <Map<String, dynamic>>[],
};

Map<String, dynamic> reviewJson({
  int id = 1,
  int rating = 5,
  String body = 'Great place',
}) => {
  'id': id,
  'rating': rating,
  'body': body,
  'created_at': '2026-11-01T10:00:00.000Z',
};

/// backend ปลอมของ owner: ตอบตาม path ที่ส่งมา ที่เหลือตอบ 404
/// [dorms] = หอของ owner, [reviews] = รีวิวของแต่ละหอ (key = dorm id),
/// [verification] = ผลของ GET /api/owner/verification (null = ยังไม่เคยส่ง)
Future<http.Response> Function(http.Request) ownerApi({
  List<Map<String, dynamic>> dorms = const [],
  Map<int, List<Map<String, dynamic>>> reviews = const {},
  Map<String, dynamic>? verification,
}) {
  return (req) async {
    final path = req.url.path;
    if (req.method == 'GET') {
      if (path == '/api/owner/dormitories') {
        return jsonResponse({'dormitories': dorms});
      }
      final dorm = RegExp(r'^/api/owner/dormitories/(\d+)$').firstMatch(path);
      if (dorm != null) {
        final id = int.parse(dorm.group(1)!);
        final match = dorms.where((d) => d['id'] == id);
        if (match.isEmpty) return jsonResponse({'message': 'not found'}, 404);
        return jsonResponse({'dormitory': match.first});
      }
      final rev = RegExp(r'^/api/owner/dormitories/(\d+)/reviews$')
          .firstMatch(path);
      if (rev != null) {
        return jsonResponse({
          'reviews': reviews[int.parse(rev.group(1)!)] ?? const [],
        });
      }
      if (path == '/api/owner/verification') {
        return jsonResponse({'verification': verification});
      }
      if (path == '/api/conversations') {
        return jsonResponse({'conversations': <Object>[]});
      }
    }
    return jsonResponse({'message': 'not found'}, 404);
  };
}
