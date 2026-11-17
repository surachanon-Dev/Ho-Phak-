import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/features/owner/services/dormitory_service.dart';
import 'package:hopak_frontend/features/owner/validation/dormitory_rules.dart';
import 'package:hopak_frontend/features/owner/services/local_owner_extras.dart';
import 'package:hopak_frontend/features/owner/validation/owner_account_rules.dart';
import 'package:hopak_frontend/shared/models/dormitory.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hopak_frontend/features/owner/models/dorm_utilities.dart';
import 'package:hopak_frontend/features/owner/models/owner_reviews_bundle.dart';

void main() {
  group('DormitoryRules', () {
    test('price / rooms', () {
      expect(DormitoryRules.price('abc'), 'Enter a whole number');
      expect(DormitoryRules.price('0'), isNotNull);
      expect(DormitoryRules.price('1000001'), isNotNull);
      expect(DormitoryRules.price(' 3500 '), isNull);
      expect(DormitoryRules.totalRooms('-1'), 'Rooms cannot be negative');
      expect(DormitoryRules.availableRooms('5', '4'),
          'Available rooms cannot exceed total rooms');
      expect(DormitoryRules.availableRooms('4', '4'), isNull);
      expect(DormitoryRules.availableRooms('1', ''), isNull);
    });

    test('rate and billing', () {
      expect(DormitoryRules.rate(''), isNull);
      expect(DormitoryRules.rate('-1'), 'Cannot be negative');
      expect(DormitoryRules.rateRequired(' '), 'Enter the rate');
      expect(DormitoryRules.billing(null, '8'), 'Choose how it is billed');
      expect(DormitoryRules.billing(null, ''), isNull);
    });

    test('pickLimit stops at 10 images and 5 per pick', () {
      expect(DormitoryRules.pickLimit(0), 5);
      expect(DormitoryRules.pickLimit(7), 3);
      expect(DormitoryRules.pickLimit(10), 0);
    });
  });

  group('OwnerAccountRules', () {
    test('password', () {
      expect(OwnerAccountRules.newPassword('short', current: 'x'),
          'Use at least 8 characters');
      expect(OwnerAccountRules.newPassword('password1', current: 'password1'),
          'New password must be different');
      expect(OwnerAccountRules.newPassword('password2', current: 'password1'),
          isNull);
      expect(OwnerAccountRules.confirmPassword('a', next: 'b'),
          'Passwords do not match');
    });

    test('phone', () {
      expect(OwnerAccountRules.phone(''), 'Enter your phone number');
      expect(OwnerAccountRules.phone('12'), 'Enter a valid phone number');
      expect(OwnerAccountRules.phone('081-234-5678'), isNull);
      expect(
        OwnerAccountRules.passwordForPhoneChange('', phoneChanged: true),
        isNotNull,
      );
      expect(
        OwnerAccountRules.passwordForPhoneChange('', phoneChanged: false),
        isNull,
      );
    });
  });

  test('buildInput sends rate only in Set price mode', () async {
    SharedPreferences.setMockInitialValues({});
    final api = ApiClient(tokenProvider: () => null);
    final c = DormitoryService(api, LocalOwnerExtras(userId: () => 1));
    DormitoryInput build(UtilityMode water) => c.buildInput(
      name: ' Dorm ',
      zone: 'Z',
      latitude: '19.03',
      longitude: '99.89',
      price: '3500',
      totalRooms: '10',
      availableRooms: '2',
      waterMode: water,
      waterRateText: '18',
      waterType: 'per_unit',
      electricityMode: UtilityMode.notSpecified,
      electricityRateText: '8',
      electricityType: 'per_unit',
      address: '  ',
      description: 'hi',
      contactPhone: '',
      amenityIds: {1, 2},
    );

    final set = build(UtilityMode.setPrice).toJson();
    expect(set['name'], 'Dorm');
    expect(set['water_rate'], 18);
    expect(set['electricity_rate'], isNull);
    expect(set['address'], isNull);

    final included = build(UtilityMode.included).toJson();
    expect(included['water_rate'], isNull);
    expect(included['water_billing_type'], isNull);
  });

  test('OwnerReviewsBundle.average is null when empty', () {
    expect(OwnerReviewsBundle.average(const []), isNull);
  });
}
