// ผู้รับผิดชอบ: Plub (เจ้าของหอ)
// unit test: กติกาตรวจฟอร์มหอ (DormitoryRules), สถานะหอ, อัตราค่าน้ำไฟ
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/model/dorm_utilities.dart';
import 'package:hopak_frontend/model/dormitory.dart';
import 'package:hopak_frontend/modules/owner/validation/dormitory_rules.dart';

import '../../../helpers/owner_data.dart';

void main() {
  group('DormitoryRules', () {
    test('1. required rejects blank text', () {
      expect(DormitoryRules.required(null), isNotNull);
      expect(DormitoryRules.required('   '), isNotNull);
      expect(DormitoryRules.required('Baan Suan'), isNull);
    });

    test('2. totalRooms accepts 0 or more but not negatives or text', () {
      expect(DormitoryRules.totalRooms('0'), isNull);
      expect(DormitoryRules.totalRooms('-1'), 'Rooms cannot be negative');
      expect(DormitoryRules.totalRooms('ten'), 'Enter a whole number');
    });

    test('3. availableRooms checks the sign and the total', () {
      expect(DormitoryRules.availableRooms('-1', '10'), isNotNull);
      expect(DormitoryRules.availableRooms('11', '10'), isNotNull);
      expect(DormitoryRules.availableRooms('10', '10'), isNull);
    });

    test('4. rate may be empty, but not negative or text', () {
      expect(DormitoryRules.rate(''), isNull);
      expect(DormitoryRules.rate('8.5'), isNull);
      expect(DormitoryRules.rate('-1'), 'Cannot be negative');
      expect(DormitoryRules.rate('abc'), 'Enter a number');
    });

    test('5. rateRequired needs a value', () {
      expect(DormitoryRules.rateRequired(''), 'Enter the rate');
      expect(DormitoryRules.rateRequired('8'), isNull);
    });

    test('6. billing is needed only when a rate is typed', () {
      expect(DormitoryRules.billing(null, ''), isNull);
      expect(DormitoryRules.billing(null, '8'), 'Choose how it is billed');
      expect(DormitoryRules.billing(BillingType.perUnit, '8'), isNull);
    });

    test('7. pickLimit allows at most 5 per pick and 10 per dorm', () {
      expect(DormitoryRules.pickLimit(0), 5);
      expect(DormitoryRules.pickLimit(7), 3);
      expect(DormitoryRules.pickLimit(10), 0);
    });
  });

  group('Dormitory model', () {
    test('8. reads the owner JSON', () {
      final d = Dormitory.fromJson(
        ownerDormJson(id: 3, name: 'Baan Rim', price: 4500, total: 8),
      );

      expect(d.id, 3);
      expect(d.name, 'Baan Rim');
      expect(d.pricePerMonth, 4500);
      expect(d.totalRooms, 8);
      expect(d.latitude, closeTo(19.95, 0.0001));
    });

    test('9. keeps the admin reason of a rejected dorm', () {
      final d = Dormitory.fromJson(
        ownerDormJson(status: 'rejected', rejectionReason: 'Blurry photos'),
      );

      expect(d.status, DormStatus.rejected);
      expect(d.statusReason, 'Blurry photos');
    });

    test('10. a suspended dorm cannot be edited', () {
      expect(
        Dormitory.fromJson(ownerDormJson(status: 'suspended')).canEdit,
        isFalse,
      );
      expect(
        Dormitory.fromJson(ownerDormJson(status: 'published')).canEdit,
        isTrue,
      );
    });

    test('11. every status has an English label', () {
      expect(DormStatus.label(DormStatus.pending), 'Pending review');
      expect(DormStatus.label(DormStatus.published), 'Published');
      expect(DormStatus.label(DormStatus.changesPending), 'Changes pending');
      expect(DormStatus.label(DormStatus.rejected), 'Rejected');
      expect(DormStatus.label(DormStatus.hidden), 'Hidden');
      expect(DormStatus.label(DormStatus.suspended), 'Suspended');
    });
  });

  group('utilityModeFor', () {
    test('12. a rate means Set price', () {
      expect(utilityModeFor(rate: 8), UtilityMode.setPrice);
    });

    test('13. no rate falls back to the saved mode or Not specified', () {
      expect(utilityModeFor(rate: null), UtilityMode.notSpecified);
      expect(
        utilityModeFor(rate: null, saved: UtilityMode.included),
        UtilityMode.included,
      );
      expect(
        utilityModeFor(rate: null, saved: UtilityMode.setPrice),
        UtilityMode.notSpecified,
      );
    });
  });
}
