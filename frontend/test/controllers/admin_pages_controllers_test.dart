import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/controllers/admin_activity_log_controller.dart';
import 'package:hopak_frontend/controllers/admin_reviews_controller.dart';
import 'package:hopak_frontend/controllers/admin_settings_controller.dart';
import 'package:hopak_frontend/services/admin_service.dart';
import 'package:hopak_frontend/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/admin_test_helpers.dart';

void main() {
  group('Settings controller', () {
    test('loads the support phone from the signed-in account', () async {
      final services = servicesWith((request) async {
        expect(request.url.path, '/api/me');
        return jsonResponse(adminAccountFixture);
      });
      final controller = _settings(services);

      expect(await controller.loadAccount(), isTrue);
      expect(controller.account?.username, 'Test Admin');
      expect(controller.supportPhone, '0800000000');
      expect(controller.activity, AdminSettingsActivity.idle);
    });

    test('mismatched passwords never reach the updater', () async {
      var writes = 0;
      final controller = _settings(
        servicesWith((_) async => jsonResponse({})),
        updatePassword:
            ({required currentPassword, required newPassword}) async {
              writes++;
            },
      );

      expect(
        await controller.changePassword(
          currentPassword: 'old-password',
          newPassword: 'new-password',
          confirmPassword: 'another-password',
        ),
        isFalse,
      );
      expect(writes, 0);
      expect(
        controller.error,
        isA<ApiException>().having(
          (error) => error.statusCode,
          'status code',
          400,
        ),
      );
    });

    test('reports unavailable when there is no password endpoint', () async {
      var requests = 0;
      final controller = _settings(
        servicesWith((_) async {
          requests++;
          return jsonResponse({});
        }),
      );

      expect(
        await controller.changePassword(
          currentPassword: 'old-password',
          newPassword: 'new-password',
          confirmPassword: 'new-password',
        ),
        isFalse,
      );
      expect(requests, 0);
      expect(
        controller.error,
        isA<ApiException>().having(
          (error) => error.statusCode,
          'status code',
          501,
        ),
      );
    });

    test(
      'passes valid passwords to the configured updater as entered',
      () async {
        final attempts = <(String, String)>[];
        final controller = _settings(
          servicesWith((_) async => jsonResponse({})),
          updatePassword:
              ({required currentPassword, required newPassword}) async {
                attempts.add((currentPassword, newPassword));
              },
        );

        expect(
          await controller.changePassword(
            currentPassword: ' old-password',
            newPassword: 'new-password ',
            confirmPassword: 'new-password ',
          ),
          isTrue,
        );
        expect(attempts, [(' old-password', 'new-password ')]);
        expect(controller.error, isNull);
      },
    );

    test(
      'sign-out clears the local session even if the server is unavailable',
      () async {
        SharedPreferences.setMockInitialValues({
          'jwt_token': 'widget-test-token',
        });
        final services = servicesWith((request) async {
          if (request.url.path == '/api/me') {
            return jsonResponse(adminAccountFixture);
          }
          return jsonResponse({'message': 'Offline'}, 503);
        });
        await services.tokens.load();
        final controller = _settings(services);
        await controller.loadAccount();

        expect(await controller.signOut(), isTrue);
        expect(services.tokens.token, isNull);
        expect(controller.account, isNull);
        expect(controller.supportPhone, isNull);
      },
    );
  });

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
