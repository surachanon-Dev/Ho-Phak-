import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/owner/services/api_owner_extras.dart';
import 'package:hopak_frontend/features/owner/services/dormitory_service.dart';
import 'package:hopak_frontend/features/owner/controllers/owner_dashboard_controller.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> _dorm(int id, String status) => {
  'id': id,
  'owner_id': 21,
  'name': 'หอ $id',
  'zone': 'หน้ามอ',
  'latitude': '19.88',
  'longitude': '99.83',
  'price_per_month': 3000,
  'total_rooms': 5,
  'available_rooms': 2,
  'status': status,
};

void main() {
  OwnerDashboardController build(http.Client client) {
    final api = ApiClient(tokenProvider: () => 't', client: client);
    return OwnerDashboardController(DormitoryService(api, ApiOwnerExtras(api)));
  }

  test('load เก็บรายการหอและสรุปตามสถานะ', () async {
    final c = build(MockClient((req) async => _json({
      'dormitories': [_dorm(1, 'published'), _dorm(2, 'pending')],
    })));
    expect(c.showFullLoader, isTrue);

    expect(await c.load(), isTrue);

    expect(c.items.length, 2);
    expect(c.showFullLoader, isFalse);
    expect(c.summary, isNotNull);
    expect(c.loading, isFalse);
  });

  test('load ล้มเหลวเก็บ error และคืน false', () async {
    final c = build(MockClient((req) async => _json({'message': 'x'}, 500)));
    expect(await c.load(), isFalse);
    expect(c.error, isA<ApiException>());
    expect(c.items, isEmpty);
  });
}
