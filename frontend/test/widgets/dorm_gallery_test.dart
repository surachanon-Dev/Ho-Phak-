// ทดสอบ: รูปหอเลื่อนได้ทั้งปัดนิ้ว ลากเมาส์ และปุ่มลูกศร (ใช้ร่วมทุก role)
// Run: flutter test test/widgets/dorm_gallery_test.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/model/dormitory.dart';
import 'package:hopak_frontend/widgets/dorm_gallery.dart';

final _images = [
  for (var i = 1; i <= 3; i++) DormImage(id: i, filePath: 'uploads/$i.jpg'),
];

Future<List<int>> _pump(WidgetTester tester) async {
  final pages = <int>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 250,
          child: DormGallery(images: _images, onPageChanged: pages.add),
        ),
      ),
    ),
  );
  return pages;
}

void main() {
  testWidgets('touch swipe moves to the next photo', (tester) async {
    final pages = await _pump(tester);
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(pages, [1]);
  });

  testWidgets('mouse drag also moves the photo (web / desktop)', (
    tester,
  ) async {
    final pages = await _pump(tester);
    await tester.fling(
      find.byType(PageView),
      const Offset(-300, 0),
      1000,
      deviceKind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(pages, [1]);
  });

  testWidgets('arrows step through photos and hide at the ends', (
    tester,
  ) async {
    final pages = await _pump(tester);
    expect(find.byTooltip('Previous photo'), findsNothing);

    await tester.tap(find.byTooltip('Next photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Next photo'));
    await tester.pumpAndSettle();
    expect(pages, [1, 2]);
    expect(find.byTooltip('Next photo'), findsNothing);

    await tester.tap(find.byTooltip('Previous photo'));
    await tester.pumpAndSettle();
    expect(pages, [1, 2, 1]);
  });
}
