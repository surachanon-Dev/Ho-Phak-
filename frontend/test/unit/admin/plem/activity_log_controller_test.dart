// ผู้รับผิดชอบ: Plem (แอดมิน)
// เทสต์ unit ของ controller ที่ระบุในชื่อ group
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/admin/activity_log/admin_activity_log_controller.dart';
import 'package:hopak_frontend/features/admin/reviews/admin_reviews_controller.dart';
import 'package:hopak_frontend/features/admin/settings/admin_settings_controller.dart';
import 'package:hopak_frontend/features/admin/services/admin_service.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/admin_test_helpers.dart';

void main() {

  group('Activity Log controller', () {
    test(
      'combines action and date filters without losing the original rows',
      () async {
        final controller = _logs((request) async {
          expect(request.url.path, '/api/admin/logs');
          return jsonResponse({
            'logs': [
              logFixture,
              {...logFixture, 'id': 30, 'action': 'review.publish'},
              {...logFixture, 'id': 29, 'created_at': '2026-11-01T00:00:00Z'},
            ],
          });
        });

        await controller.refresh();
        controller.setFilters(
          action: 'review.hide',
          since: DateTime.utc(2026, 11, 8, 9, 15),
        );

        expect(controller.entries.map((entry) => entry['id']), [31]);
        expect(controller.availableActions, ['review.hide', 'review.publish']);
        controller.setFilters();
        expect(controller.entries.map((entry) => entry['id']), [31, 30, 29]);
      },
    );

    test('a failed refresh preserves the last loaded Activity Log', () async {
      var reads = 0;
      final controller = _logs((_) async {
        reads++;
        return reads == 1
            ? jsonResponse({
                'logs': [logFixture],
              })
            : jsonResponse({'message': 'Log unavailable'}, 503);
      });
      final loadingStates = <bool>[];
      controller.addListener(() => loadingStates.add(controller.isLoading));

      await controller.refresh();
      await controller.refresh();

      expect(controller.entries.single['id'], 31);
      expect(controller.error, isA<ApiException>());
      expect(loadingStates, [true, false, true, false]);
    });
  });

}

AdminSettingsController _settings(
  TestAppServices services, {
  AdminPasswordUpdater? updatePassword,
}) {
  final controller = AdminSettingsController(
    api: services.api,
    auth: services.auth,
    updatePassword: updatePassword,
  );
  addTearDown(controller.dispose);
  return controller;
}

AdminActivityLogController _logs(RequestHandler handler) {
  final controller = AdminActivityLogController(
    AdminService(servicesWith(handler).api),
  );
  addTearDown(controller.dispose);
  return controller;
}

AdminReviewsController _reviews(RequestHandler handler) {
  final controller = AdminReviewsController(
    AdminService(servicesWith(handler).api),
  );
  addTearDown(controller.dispose);
  return controller;
}
