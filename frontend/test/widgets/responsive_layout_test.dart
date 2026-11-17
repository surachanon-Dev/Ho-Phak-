import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/utils/responsive.dart';

void main() {
  testWidgets('StackOnNarrow เรียงแนวนอนบนจอกว้าง และซ้อนแนวตั้งบนจอแคบ', (tester) async {
    Widget build(double width) => MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: width,
              child: StackOnNarrow(
                row: const Row(children: [
                  Expanded(child: Text('A')),
                  SizedBox(width: 14),
                  Expanded(child: Text('B')),
                ]),
              ),
            ),
          ),
        );

    await tester.pumpWidget(build(700));
    expect(find.byType(Row), findsOneWidget);

    await tester.pumpWidget(build(400));
    expect(find.byType(Column), findsWidgets);
    expect(tester.getTopLeft(find.text('B')).dy,
        greaterThan(tester.getTopLeft(find.text('A')).dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('MinWidthScroll เลื่อนแนวนอนเมื่อพื้นที่แคบกว่าความกว้างขั้นต่ำ', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 320,
          child: MinWidthScroll(
            minWidth: 760,
            child: Container(key: const Key('table'), color: Colors.red),
          ),
        ),
      ),
    ));
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('table'))).width, 760);
    expect(tester.takeException(), isNull);
  });

  testWidgets('MinWidthScroll ไม่เลื่อนเมื่อพื้นที่กว้างพอ', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MinWidthScroll(
          minWidth: 760,
          child: Container(key: const Key('wide')),
        ),
      ),
    ));
    expect(find.byType(SingleChildScrollView), findsNothing);
  });
}
