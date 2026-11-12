import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/services/api_client.dart';
import 'package:hopak_frontend/services/local_owner_extras.dart';
import 'package:hopak_frontend/services/owner_extras.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late int? uid;
  late LocalOwnerExtras extras;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    uid = 1;
    extras = LocalOwnerExtras(userId: () => uid);
  });

  test('amenities: local ids never go to the server, existing ids are kept', () {
    expect(extras.amenityIdsForServer([1, 2, 3], [7]), [7]);
    expect(extras.amenityIdsForServer([1, 2, 3], const []), isEmpty);
  });

  test('amenities: selection is saved per dorm', () async {
    await extras.saveDormAmenityIds(5, [1, 6]);
    expect(await extras.dormAmenityIds(5, const []), [1, 6]);
    expect(await extras.dormAmenityIds(6, const []), isEmpty);
    expect((await extras.amenities()).length, localAmenityCatalog.length);
  });

  test('data is keyed by user id', () async {
    await extras.saveDormAmenityIds(5, [1]);
    uid = 2;
    expect(await extras.dormAmenityIds(5, const []), isEmpty);
  });

  test('utilityModeFor: rate wins, otherwise saved mode', () {
    expect(utilityModeFor(rate: 8), UtilityMode.setPrice);
    expect(
      utilityModeFor(rate: 8, saved: UtilityMode.included),
      UtilityMode.setPrice,
    );
    expect(
      utilityModeFor(rate: null, saved: UtilityMode.included),
      UtilityMode.included,
    );
    expect(utilityModeFor(rate: null), UtilityMode.notSpecified);
    expect(
      utilityModeFor(rate: null, saved: UtilityMode.setPrice),
      UtilityMode.notSpecified,
    );
  });

  test('utilities round trip', () async {
    await extras.saveUtilities(
      3,
      const DormUtilities(
        water: UtilityMode.included,
        electricity: UtilityMode.setPrice,
      ),
    );
    final u = await extras.utilities(3);
    expect(u!.water, UtilityMode.included);
    expect(u.electricity, UtilityMode.setPrice);
    expect(await extras.utilities(4), isNull);
  });

  test('delete hides the dorm id only for this user', () async {
    await extras.deleteDorm(9);
    expect(await extras.deletedDormIds(), {9});
    uid = 2;
    expect(await extras.deletedDormIds(), isEmpty);
  });

  test('report review keeps reason', () async {
    await extras.reportReview(11, 'Not accurate');
    final r = await extras.reports();
    expect(r[11]!.reason, 'Not accurate');
    expect(r.containsKey(12), isFalse);
  });

  test('profile: name saved, phone change needs password and stays pending',
      () async {
    await extras.saveProfile(
      firstName: 'Somchai',
      surname: 'Jaidee',
      phone: '0812345678',
    );
    var p = await extras.profile();
    expect(p.fullName, 'Somchai Jaidee');
    expect(p.phone, '0812345678');
    expect(p.pendingPhone, isNull);

    expect(
      () => extras.saveProfile(
        firstName: 'Somchai',
        surname: 'Jaidee',
        phone: '0819990000',
      ),
      throwsA(isA<ApiException>()),
    );

    p = await extras.saveProfile(
      firstName: 'Somchai',
      surname: 'Jaidee',
      phone: '0819990000',
      password: 'secret123',
    );
    expect(p.phone, '0812345678');
    expect(p.pendingPhone, '0819990000');

    p = await extras.saveProfile(
      firstName: 'Somchai',
      surname: 'Jaidee',
      phone: '0812345678',
    );
    expect(p.pendingPhone, isNull);
  });

  test('profile photo: null keeps, empty removes', () async {
    await extras.saveProfile(
      firstName: 'A',
      surname: 'B',
      phone: '',
      photoBase64: 'abc',
    );
    await extras.saveProfile(firstName: 'A2', surname: 'B', phone: '');
    expect((await extras.profile()).photoBase64, 'abc');
    await extras.saveProfile(
      firstName: 'A2',
      surname: 'B',
      phone: '',
      photoBase64: '',
    );
    expect((await extras.profile()).photoBase64, isNull);
  });

  test('change password checks the length', () async {
    expect(
      () => extras.changePassword(current: 'x', next: 'short'),
      throwsA(isA<ApiException>()),
    );
    await extras.changePassword(current: 'x', next: 'longenough1');
  });

  test('notification prefs: defaults then saved', () async {
    var p = await extras.notificationPrefs();
    expect([p.messages, p.approvals, p.reviews], [true, true, false]);
    await extras.saveNotificationPrefs(p.copyWith(reviews: true, messages: false));
    p = await extras.notificationPrefs();
    expect([p.messages, p.approvals, p.reviews], [false, true, true]);
  });
}
