import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/ui/format.dart';

void main() {
  final now = DateTime(2026, 11, 9, 15, 30);

  test('relativeDay: วันนี้ / เมื่อวาน / กี่วันก่อน / สัปดาห์ก่อน', () {
    expect(relativeDay('2026-11-09T01:00:00', now: now), 'Today');
    expect(relativeDay('2026-11-08T23:00:00', now: now), 'Yesterday');
    expect(relativeDay('2026-11-06T10:00:00', now: now), '3 days ago');
    expect(relativeDay('2026-11-02T10:00:00', now: now), '1 week ago');
    expect(relativeDay('2026-10-10T10:00:00', now: now), '10/10/2026');
  });

  test('relativeDay: อ่านเวลาไม่ได้ให้คืนข้อความเดิม', () {
    expect(relativeDay('not a date', now: now), 'not a date');
  });

  test('chatTime: วันนี้เป็น HH:mm, เมื่อวาน, ชื่อวัน, วัน/เดือน', () {
    expect(chatTime('2026-11-09T10:06:00', now: now), '10:06');
    expect(chatTime('2026-11-08T10:06:00', now: now), 'Yesterday');
    expect(chatTime('2026-11-06T10:06:00', now: now), 'Fri');
    expect(chatTime('2026-10-01T10:06:00', now: now), '1/10');
    expect(chatTime(null, now: now), '');
    expect(chatTime('bad', now: now), '');
  });

  test('kmFromMfu: ตำแหน่ง MFU = 0.0 และห่างออกไปประมาณ 1.1 กม. ต่อ 0.01 องศา', () {
    expect(kmFromMfu(19.8801, 99.8323), '0.0');
    final km = double.parse(kmFromMfu(19.8901, 99.8323));
    expect(km, inInclusiveRange(1.0, 1.2));
  });
}
