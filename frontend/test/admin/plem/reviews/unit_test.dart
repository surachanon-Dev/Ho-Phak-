// ผู้รับผิดชอบ: Plem (แอดมิน)
// เทสต์ unit ของ controller ที่ระบุในชื่อ group
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/modules/admin/reviews/controller/admin_reviews_controller.dart';
import 'package:hopak_frontend/services/admin_service.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:http/http.dart' as http;

import '../plem_test_helpers.dart';

void main() {
  group('Reviews controller', () {
    test(
      'Kept maps to published and an older Open response cannot overwrite it',
      () async {
        final open = Completer<http.Response>();
        final requestedStatuses = <String?>[];
        final controller = _reviews((request) async {
          final status = request.url.queryParameters['status'];
          requestedStatuses.add(status);
          if (status == 'pending') return open.future;
          return jsonResponse({
            'reviews': [
              {...reviewFixture, 'id': 12, 'status': 'published'},
            ],
          });
        });

        final first = controller.refresh();
        await controller.selectStatus(AdminReviewStatus.kept);
        open.complete(
          jsonResponse({
            'reviews': [reviewFixture],
          }),
        );
        await first;

        expect(requestedStatuses, ['pending', 'published']);
        expect(controller.status, AdminReviewStatus.kept);
        expect(controller.reviews.single['id'], 12);
        expect(controller.isLoading, isFalse);
      },
    );

    test('a blank hide reason never sends an API request', () async {
      var requests = 0;
      final controller = _reviews((_) async {
        requests++;
        return jsonResponse({});
      });

      expect(await controller.hideReview(9, '   '), isFalse);
      expect(requests, 0);
      expect(controller.actionError, isA<ApiException>());
    });

    test(
      'hiding submits the trimmed reason and reloads the open list',
      () async {
        final writes = <String, Object?>{};
        final controller = _reviews((request) async {
          if (request.method == 'POST') {
            writes[request.url.path] = jsonDecode(request.body);
            return jsonResponse({});
          }
          return jsonResponse({
            'reviews': writes.isEmpty ? [reviewFixture] : [],
          });
        });

        await controller.refresh();
        expect(controller.reviews.single['id'], 9);
        expect(await controller.hideReview(9, '  Spam  '), isTrue);

        expect(writes, {
          '/api/admin/reviews/9/hide': {'reason': 'Spam'},
        });
        expect(controller.reviews, isEmpty);
      },
    );

    test(
      'a completed publish is not sent again when its refresh fails',
      () async {
        var reads = 0;
        final writes = <String>[];
        final controller = _reviews((request) async {
          if (request.method == 'POST') {
            writes.add(request.url.path);
            return jsonResponse({});
          }
          reads++;
          if (reads == 1) {
            return jsonResponse({
              'reviews': [reviewFixture],
            });
          }
          if (reads == 2) {
            return jsonResponse({'message': 'Refresh failed'}, 503);
          }
          return jsonResponse({'reviews': []});
        });

        await controller.refresh();
        expect(await controller.publishReview(9), isTrue);
        expect(controller.actionError, isNull);
        expect(controller.loadError, isA<ApiException>());
        expect(controller.reviews, isEmpty);

        await controller.refresh();
        expect(controller.loadError, isNull);
        expect(writes, ['/api/admin/reviews/9/publish']);
      },
    );
  });
}

AdminReviewsController _reviews(RequestHandler handler) {
  final controller = AdminReviewsController(
    AdminService(servicesWith(handler).api),
  );
  addTearDown(controller.dispose);
  return controller;
}
