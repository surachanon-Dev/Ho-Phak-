// ผู้รับผิดชอบ: Kren (เจ้าของหอ)
// unit test: NotificationSettingsController (โหลด สลับสวิตช์ และย้อนค่าเมื่อบันทึกไม่ได้)
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:hopak_frontend/model/notification_prefs.dart';
import 'package:hopak_frontend/modules/owner/notification_settings/controller/notification_settings_controller.dart';
import 'package:hopak_frontend/services/owner_account_service.dart';
import 'package:mocktail/mocktail.dart';

class MockOwnerAccountService extends Mock implements OwnerAccountService {}

void main() {
  late MockOwnerAccountService account;
  late NotificationSettingsController controller;

  setUpAll(() => registerFallbackValue(const NotificationPrefs()));

  setUp(() {
    account = MockOwnerAccountService();
    controller = NotificationSettingsController(account);
    when(() => account.notificationPrefs())
        .thenAnswer((_) async => const NotificationPrefs());
  });

  test('1. nothing is loaded before load()', () {
    expect(controller.prefs, isNull);
  });

  test('2. load keeps the saved settings', () async {
    when(() => account.notificationPrefs()).thenAnswer(
      (_) async => const NotificationPrefs(
        messages: false,
        approvals: true,
        reviews: true,
      ),
    );

    expect(await controller.load(), isTrue);

    expect(controller.prefs!.messages, isFalse);
    expect(controller.prefs!.approvals, isTrue);
    expect(controller.prefs!.reviews, isTrue);
  });

  test('3. the defaults are messages and approvals on, reviews off', () async {
    await controller.load();

    expect(controller.prefs!.messages, isTrue);
    expect(controller.prefs!.approvals, isTrue);
    expect(controller.prefs!.reviews, isFalse);
  });

  test('4. load that fails keeps the error', () async {
    when(() => account.notificationPrefs()).thenThrow(ApiException(500, 'x'));

    expect(await controller.load(), isFalse);

    expect(controller.error, isA<ApiException>());
    expect(controller.prefs, isNull);
  });

  test('5. update shows the new value and saves it', () async {
    when(() => account.saveNotificationPrefs(any())).thenAnswer((_) async {});
    await controller.load();

    final next = controller.prefs!.copyWith(reviews: true);
    expect(await controller.update(next), isTrue);

    expect(controller.prefs!.reviews, isTrue);
    verify(() => account.saveNotificationPrefs(next)).called(1);
  });

  test('6. update that fails goes back to the old value', () async {
    when(() => account.saveNotificationPrefs(any()))
        .thenThrow(ApiException(500, 'down'));
    await controller.load();

    final ok = await controller.update(
      controller.prefs!.copyWith(messages: false),
    );

    expect(ok, isFalse);
    expect(controller.prefs!.messages, isTrue);
    expect(controller.error, isA<ApiException>());
  });

  test('7. the new value is visible while saving', () async {
    when(() => account.saveNotificationPrefs(any())).thenAnswer((_) async {});
    await controller.load();
    final seen = <bool>[];
    controller.addListener(() => seen.add(controller.prefs!.reviews));

    await controller.update(controller.prefs!.copyWith(reviews: true));

    expect(seen.first, isTrue); // แสดงผลทันทีก่อนบันทึกเสร็จ
  });

  test('8. NotificationPrefs reads and writes the backend JSON', () {
    final prefs = NotificationPrefs.fromJson({
      'messages': false,
      'approvals': true,
      'reviews': true,
    });

    expect(prefs.messages, isFalse);
    expect(prefs.toJson(), {
      'messages': false,
      'approvals': true,
      'reviews': true,
    });
  });
}
