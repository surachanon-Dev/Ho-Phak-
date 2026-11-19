// ผู้รับผิดชอบ: Big (นักศึกษา)
// unit test: model หอพักที่ทุกหน้าของนักศึกษาใช้ (รูปปก, ชื่อโซน, แปลง JSON)
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/model/dormitory.dart';
import 'package:hopak_frontend/model/favorite.dart';

import '../../../helpers/student_data.dart';

void main() {
  test('1. Dormitory reads the backend JSON', () {
    final d = Dormitory.fromJson(
      dormJson(name: 'Sunrise Dorm', price: 3500, rating: 4.5, reviewCount: 2),
    );

    expect(d.name, 'Sunrise Dorm');
    expect(d.pricePerMonth, 3500);
    expect(d.ratingAvg, 4.5);
    expect(d.reviewCount, 2);
  });

  test('2. Dormitory uses cover_image when it has no images', () {
    final d = Dormitory.fromJson({
      ...dormJson(),
      'cover_image': 'uploads/a.jpg',
    });

    expect(d.coverUrl, endsWith('/uploads/a.jpg'));
  });

  test('3. Favorite without a picture has no cover', () {
    expect(Favorite.fromJson(favoriteJson()).coverUrl, isNull);
  });

  test('4. zoneLabel turns zone names into English', () {
    expect(zoneLabel('หน้ามอ'), 'Front gate');
    expect(zoneLabel('หลังมอ'), 'Back gate');
    expect(zoneLabel('คชพลแลนด์'), 'Kotchapol Land');
    expect(zoneLabel('อื่น ๆ'), 'อื่น ๆ'); // ไม่รู้จัก คืนค่าเดิม
  });
}
