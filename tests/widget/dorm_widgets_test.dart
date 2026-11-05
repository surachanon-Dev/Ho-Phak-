// Widget Test: dorm card, search page, Owner dorm form
// TODO: change the import, class name and model to match the real code
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ho_phak/models/dormitory.dart'; // TODO
import 'package:ho_phak/widgets/dorm_card.dart'; // TODO
import 'package:ho_phak/views/owner/dorm_form_page.dart'; // TODO

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

final sample = Dormitory(
  id: 1,
  name: 'หอพักสุขสบาย',
  zone: 'หน้ามอ',
  latitude: 16.476,
  longitude: 102.824,
  price: 3500,
  coverImage: '',
);

void main() {
  testWidgets('WID-09 dorm card shows the name, zone and price', (tester) async {
    await tester.pumpWidget(wrap(DormCard(dorm: sample)));
    expect(find.text('หอพักสุขสบาย'), findsOneWidget);
    expect(find.textContaining('หน้ามอ'), findsOneWidget);
    expect(find.textContaining('3,500'), findsOneWidget); // check the price uses a thousands separator
  });

  testWidgets('WID-10 card without an image shows a placeholder and does not crash', (tester) async {
    await tester.pumpWidget(wrap(DormCard(dorm: sample)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('WID-11 dorm form: empty name and price show errors', (tester) async {
    await tester.pumpWidget(MaterialApp(home: const DormFormPage()));
    await tester.tap(find.byKey(const Key('dorm_save')));
    await tester.pump();
    expect(find.textContaining('กรุณา'), findsWidgets); // TODO: real message
  });

  testWidgets('WID-12 dorm form: zone dropdown has all 3 zones', (tester) async {
    await tester.pumpWidget(MaterialApp(home: const DormFormPage()));
    await tester.tap(find.byKey(const Key('dorm_zone')));
    await tester.pumpAndSettle();
    for (final z in ['หน้ามอ', 'หลังมอ', 'คชพลแลนด์']) {
      expect(find.text(z), findsWidgets);
    }
  });

  testWidgets('WID-13 dorm form: typing letters in the price field is blocked', (tester) async {
    await tester.pumpWidget(MaterialApp(home: const DormFormPage()));
    final price = find.descendant(of: find.byKey(const Key('dorm_price')), matching: find.byType(TextField));
    await tester.enterText(price, 'abc');
    await tester.pump();
    expect(find.text('abc'), findsNothing);
  });
}
