import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/controllers/admin_activity_log_controller.dart';
import 'package:hopak_frontend/controllers/admin_reviews_controller.dart';
import 'package:hopak_frontend/controllers/admin_settings_controller.dart';
import 'package:hopak_frontend/screens/admin/admin_logs_tab.dart';
import 'package:hopak_frontend/screens/admin/admin_profile_tab.dart';
import 'package:hopak_frontend/screens/admin/admin_reviews_tab.dart';
import 'package:hopak_frontend/screens/admin/admin_settings_tab.dart';
import 'package:hopak_frontend/screens/login_screen.dart';
import 'package:hopak_frontend/services/admin_service.dart';
import 'package:hopak_frontend/services/api_client.dart';
import 'package:hopak_frontend/services/app_services.dart';
import 'package:hopak_frontend/services/auth_service.dart';
import 'package:hopak_frontend/services/token_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _adminAccount = {
  'user': {
    'id': 7,
    'username': 'Test Admin',
    'phone': '0800000000',
    'role': 'admin',
    'status': 'active',
    'is_verified': 1,
  },
};

const _log = {
  'id': 31,
  'action': 'review.hide',
  'admin_name': 'Test Admin',
  'target_type': 'review',
  'target_id': 9,
  'created_at': '2026-11-08T09:15:00Z',
};

const _review = {
  'id': 9,
  'dormitory_id': 26,
  'dormitory_name': 'Hillview Dorm',
  'rating': 2,
  'body': 'Test review for moderation',
  'author': 'Test Student',
  'created_at': '2026-11-08T09:10:00Z',
  'status': 'pending',
};

void main() {
  group('Settings controller', () {
    test('loads the support phone from the signed-in account', () async {
      final services = _services((request) async {
        expect(request.url.path, '/api/me');
        return _json(_adminAccount);
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
        _services((_) async => _json({})),
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
        _services((_) async {
          requests++;
          return _json({});
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
          _services((_) async => _json({})),
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
        final services = _services((request) async {
          if (request.url.path == '/api/me') return _json(_adminAccount);
          return _json({'message': 'Offline'}, 503);
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
          return _json({
            'logs': [
              _log,
              {..._log, 'id': 30, 'action': 'review.publish'},
              {..._log, 'id': 29, 'created_at': '2026-11-01T00:00:00Z'},
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
            ? _json({
                'logs': [_log],
              })
            : _json({'message': 'Log unavailable'}, 503);
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
          return _json({
            'reviews': [
              {..._review, 'id': 12, 'status': 'published'},
            ],
          });
        });

        final first = controller.refresh();
        await controller.selectStatus(AdminReviewStatus.kept);
        open.complete(
          _json({
            'reviews': [_review],
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
        return _json({});
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
            return _json({});
          }
          return _json({
            'reviews': writes.isEmpty ? [_review] : [],
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
            return _json({});
          }
          reads++;
          if (reads == 1) {
            return _json({
              'reviews': [_review],
            });
          }
          if (reads == 2) return _json({'message': 'Refresh failed'}, 503);
          return _json({'reviews': []});
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

  group('Admin page widgets', () {
    testWidgets(
      'Settings masks all password fields',
      (tester) async {
        _desktopSize(tester);
        await tester.pumpWidget(
          MaterialApp(
            home: AdminSettingsTab(services: _services((_) async => _json({}))),
          ),
        );

        final fields = tester
            .widgetList<TextField>(find.byType(TextField))
            .toList();
        expect(fields, hasLength(3));
        expect(fields.every((field) => field.obscureText), isTrue);
      },
    );

    testWidgets('the admin account confirms sign-out and returns to Login', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'jwt_token': 'widget-test-token',
      });
      final writes = <String>[];
      final services = _services((request) async {
        if (request.method == 'POST') writes.add(request.url.path);
        return request.url.path == '/api/me' ? _json(_adminAccount) : _json({});
      });
      await services.tokens.load();
      await tester.pumpWidget(
        MaterialApp(home: AdminProfileTab(services: services)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Admin'), findsOneWidget);
      await tester.tap(find.text('ออกจากระบบ'));
      await tester.pumpAndSettle();
      expect(writes, isEmpty);

      await tester.tap(find.widgetWithText(FilledButton, 'ออกจากระบบ'));
      await tester.pumpAndSettle();
      expect(writes, ['/api/auth/logout']);
      expect(services.tokens.token, isNull);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets(
      'Activity Log displays loaded actions and refreshes an empty list',
      (tester) async {
        var reads = 0;
        final services = _services((request) async {
          expect(request.url.path, '/api/admin/logs');
          reads++;
          return _json({
            'logs': reads == 1 ? [_log] : [],
          });
        });
        await tester.pumpWidget(
          MaterialApp(home: AdminLogsTab(services: services)),
        );
        await tester.pumpAndSettle();

        expect(find.text('review.hide'), findsOneWidget);
        await tester.tap(find.byTooltip('รีเฟรช'));
        await tester.pumpAndSettle();
        expect(find.text('ยังไม่มีประวัติ'), findsOneWidget);
        expect(reads, 2);
      },
    );

    testWidgets(
      'Reviews keeps an open review and refreshes the displayed list',
      (tester) async {
        _desktopSize(tester);
        final writes = <String>[];
        final services = _services((request) async {
          if (request.method == 'POST') {
            writes.add(request.url.path);
            return _json({});
          }
          return _json({
            'reviews': writes.isEmpty ? [_review] : [],
          });
        });
        await tester.pumpWidget(
          MaterialApp(home: AdminReviewsTab(services: services)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Hillview Dorm'), findsOneWidget);
        await tester.tap(find.widgetWithText(OutlinedButton, 'Keep review'));
        await tester.pumpAndSettle();

        expect(writes, ['/api/admin/reviews/9/publish']);
        expect(find.text('Hillview Dorm'), findsNothing);
        expect(find.text('ไม่มีรีวิวในสถานะนี้'), findsOneWidget);
      },
    );
  });
}

AdminSettingsController _settings(
  _TestAppServices services, {
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

AdminActivityLogController _logs(
  Future<http.Response> Function(http.Request) handler,
) {
  final controller = AdminActivityLogController(
    AdminService(_services(handler).api),
  );
  addTearDown(controller.dispose);
  return controller;
}

AdminReviewsController _reviews(
  Future<http.Response> Function(http.Request) handler,
) {
  final controller = AdminReviewsController(
    AdminService(_services(handler).api),
  );
  addTearDown(controller.dispose);
  return controller;
}

_TestAppServices _services(
  Future<http.Response> Function(http.Request) handler,
) {
  final client = MockClient(handler);
  addTearDown(client.close);
  final tokens = TokenStore();
  return _TestAppServices(
    ApiClient(tokenProvider: () => tokens.token, client: client),
    tokens,
  );
}

class _TestAppServices implements AppServices {
  _TestAppServices(this.api, this.tokens) : auth = AuthService(api, tokens);

  @override
  final ApiClient api;

  @override
  final TokenStore tokens;

  @override
  final AuthService auth;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

http.Response _json(Object data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void _desktopSize(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1920, 1080);
  addTearDown(tester.view.reset);
}
