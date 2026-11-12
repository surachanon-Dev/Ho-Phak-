// Unit Test: text formatting (lib/core/formatters.dart)
import 'package:flutter_test/flutter_test.dart';

import 'package:hophak_frontend/core/formatters.dart';

void main() {
  test('UNIT-F01 price has a thousands separator and unit', () {
    expect(formatPrice(3500), '3,500 บาท/เดือน');
    expect(formatPrice(12000), '12,000 บาท/เดือน');
    expect(formatPrice(null), '-');
  });

  test('UNIT-F02 baht', () {
    expect(formatBaht(48500), '฿48,500');
    expect(formatBaht(null), '-');
  });

  test('UNIT-F03 distance: under 1 km in meters, otherwise km with 1 decimal', () {
    expect(formatDistance(450), '450 ม.');
    expect(formatDistance(999), '999 ม.');
    expect(formatDistance(1000), '1.0 กม.');
    expect(formatDistance(1200), '1.2 กม.');
    expect(formatDistance(null), '-');
  });

  test('UNIT-F04 water / electricity rate', () {
    expect(formatRate(18, 'per_unit'), '18 บาท/หน่วย');
    expect(formatRate(100, 'per_person_month'), '100 บาท/คน/เดือน');
    expect(formatRate(null, 'per_unit'), 'ไม่ระบุ');
  });

  test('UNIT-F05 date is dd/MM/yyyy', () {
    expect(formatDate(DateTime(2026, 11, 5)), '05/11/2026');
    expect(formatDate(null), '-');
  });

  test('UNIT-F06 every dorm status has a Thai label', () {
    for (final s in ['pending', 'published', 'rejected', 'hidden', 'suspended']) {
      expect(dormStatusLabels[s], isNotNull, reason: 'status $s has no label');
    }
  });
}
