// ผู้รับผิดชอบ: Plem (แอดมิน)
// เทสต์ unit ของ controller ที่ระบุในชื่อ group

import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/modules/admin/settings/controller/admin_settings_controller.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../plem_test_helpers.dart';

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
}

AdminSettingsController _settings(
  AppServices services, {
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
