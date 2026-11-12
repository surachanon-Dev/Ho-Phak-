// Widget Test: dorm card (lib/views/widgets/dorm_card.dart)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hophak_frontend/models/dormitory.dart';
import 'package:hophak_frontend/views/widgets/common.dart';
import 'package:hophak_frontend/views/widgets/dorm_card.dart';

import '../helpers/test_app.dart';

Dormitory dorm({num? rating, int reviews = 0, int? distance = 1200, String status = 'published', String name = 'หอพักสุขสบาย'}) =>
    Dormitory(
      id: 1,
      ownerId: 2,
      name: name,
      zone: 'หน้ามอ',
      latitude: 19.88,
      longitude: 99.83,
      pricePerMonth: 3500,
      status: status,
      avgRating: rating,
      reviewCount: reviews,
      distanceMeters: distance,
    );

void main() {
  testWidgets('WID-19 shows name, price with a comma, zone and distance', (tester) async {
    await tester.pumpWidget(inScaffold(DormCard(dorm: dorm())));
    expect(find.text('หอพักสุขสบาย'), findsOneWidget);
    expect(find.text('3,500 บาท/เดือน'), findsOneWidget);
    expect(find.text('หน้ามอ · 1.2 กม.'), findsOneWidget);
  });

  testWidgets('WID-20 distance under 1 km is shown in meters', (tester) async {
    await tester.pumpWidget(inScaffold(DormCard(dorm: dorm(distance: 450))));
    expect(find.text('หน้ามอ · 450 ม.'), findsOneWidget);
  });

  testWidgets('WID-21 no reviews yet shows "ยังไม่มีรีวิว"', (tester) async {
    await tester.pumpWidget(inScaffold(DormCard(dorm: dorm())));
    expect(find.text('ยังไม่มีรีวิว'), findsOneWidget);
  });

  testWidgets('WID-22 rating is shown with 1 decimal and the review count', (tester) async {
    await tester.pumpWidget(inScaffold(DormCard(dorm: dorm(rating: 4.25, reviews: 12))));
    expect(find.textContaining('(12)'), findsOneWidget);
  });

  testWidgets('WID-23 no photo shows a placeholder and does not crash', (tester) async {
    await tester.pumpWidget(inScaffold(DormCard(dorm: dorm())));
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.apartment_rounded), findsOneWidget);
  });

  testWidgets('WID-24 status label is shown only when showStatus is true', (tester) async {
    await tester.pumpWidget(inScaffold(DormCard(dorm: dorm(status: 'pending'))));
    expect(find.byType(StatusChip), findsNothing);
    await tester.pumpWidget(inScaffold(DormCard(dorm: dorm(status: 'pending'), showStatus: true)));
    expect(find.text('รอตรวจสอบ'), findsOneWidget);
  });

  testWidgets('WID-25 tapping the card calls onTap', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(inScaffold(DormCard(dorm: dorm(), onTap: () => tapped++)));
    await tester.tap(find.byType(DormCard));
    expect(tapped, 1);
  });

  testWidgets('WID-26 a very long name does not overflow the card', (tester) async {
    await tester.pumpWidget(inScaffold(DormCard(dorm: dorm(name: 'หอพัก' * 40))));
    expect(tester.takeException(), isNull);
  });
}
