// ผู้รับผิดชอบ: Big (นักศึกษา)
// unit test: DormSearchController (ค้นหาและตัวกรองหอพัก)
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/model/dormitory.dart';
import 'package:hopak_frontend/modules/student/search/controller/dorm_search_controller.dart';
import 'package:hopak_frontend/services/public_dormitory_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/student_data.dart';

class MockDormService extends Mock implements PublicDormitoryService {}

void main() {
  late MockDormService dorms;
  late DormSearchController controller;

  // ทุกการค้นหาตอบรายการ [result]
  void searchReturns(List<Map<String, dynamic>> result) {
    when(
      () => dorms.search(
        zone: any(named: 'zone'),
        minPrice: any(named: 'minPrice'),
        maxPrice: any(named: 'maxPrice'),
        roomsOnly: any(named: 'roomsOnly'),
        query: any(named: 'query'),
        sort: any(named: 'sort'),
      ),
    ).thenAnswer((_) async => result.map(Dormitory.fromJson).toList());
  }

  setUp(() {
    dorms = MockDormService();
    controller = DormSearchController(dorms);
    searchReturns([dormJson()]);
  });

  test('1. price box accepts numbers only', () {
    expect(parsePriceInput(' 3000 '), 3000);
    expect(parsePriceInput(''), isNull);
    expect(parsePriceInput('abc'), isNull);
    expect(parsePriceInput('-5'), isNull);
  });

  test('2. search sends every filter to the backend', () async {
    controller
      ..setQuery('sun')
      ..setZone('หน้ามอ')
      ..setMinPrice('2000')
      ..setMaxPrice('4000')
      ..setRoomsOnly(true)
      ..setSort('price_asc');

    expect(await controller.search(), isTrue);

    verify(
      () => dorms.search(
        zone: 'หน้ามอ',
        query: 'sun',
        minPrice: 2000,
        maxPrice: 4000,
        roomsOnly: true,
        sort: 'price_asc',
      ),
    ).called(1);
    expect(controller.items, hasLength(1));
  });

  test('3. min price above max price is not sent', () async {
    controller
      ..setMinPrice('5000')
      ..setMaxPrice('1000');

    expect(await controller.search(), isFalse);

    expect(controller.filterError, isNotNull);
    verifyNever(
      () => dorms.search(
        zone: any(named: 'zone'),
        minPrice: any(named: 'minPrice'),
        maxPrice: any(named: 'maxPrice'),
        roomsOnly: any(named: 'roomsOnly'),
        query: any(named: 'query'),
        sort: any(named: 'sort'),
      ),
    );
  });

  test('4. reset clears every filter', () async {
    controller
      ..setQuery('sun')
      ..setZone('หน้ามอ')
      ..setRoomsOnly(true);
    expect(controller.hasActiveFilters, isTrue);

    await controller.reset();

    expect(controller.hasActiveFilters, isFalse);
    expect(controller.filters.zone, isNull);
  });

  test('5. Top rated is sorted in the app, highest rating first', () async {
    searchReturns([
      dormJson(id: 1, name: 'Low', rating: 3.0, reviewCount: 2),
      dormJson(id: 2, name: 'No reviews'),
      dormJson(id: 3, name: 'High', rating: 4.8, reviewCount: 5),
    ]);
    controller.setSort('rating');

    await controller.search();

    // backend เรียงแบบ rating ไม่ได้ แอปจึงส่ง newest แล้วเรียงเอง
    verify(
      () => dorms.search(
        zone: any(named: 'zone'),
        minPrice: any(named: 'minPrice'),
        maxPrice: any(named: 'maxPrice'),
        roomsOnly: any(named: 'roomsOnly'),
        query: any(named: 'query'),
        sort: 'newest',
      ),
    ).called(1);
    expect(controller.items.map((d) => d.name), ['High', 'Low', 'No reviews']);
  });
}
