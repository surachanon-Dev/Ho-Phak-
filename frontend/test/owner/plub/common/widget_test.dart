// ผู้รับผิดชอบ: Plub (เจ้าของหอ)
// widget test: widget ที่หน้า owner ใช้ร่วมกัน (StatusChip, SettingsGroup, OwnerBody)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/core/utils/status_style.dart';
import 'package:hopak_frontend/model/dormitory.dart';
import 'package:hopak_frontend/modules/owner/widgets/owner_ui.dart';

Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('1. StatusChip shows the English label of every status', (
    tester,
  ) async {
    for (final status in [
      DormStatus.pending,
      DormStatus.published,
      DormStatus.changesPending,
      DormStatus.rejected,
      DormStatus.hidden,
      DormStatus.suspended,
    ]) {
      await tester.pumpWidget(host(StatusChip(displayStatus: status)));
      expect(find.text(DormStatus.label(status)), findsOneWidget);
    }
    expect(DormStatus.label(DormStatus.suspended), 'Suspended');
  });

  testWidgets('2. SettingsGroup shows its title in capitals and its rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SettingsGroup(
          title: 'Account',
          children: [
            ListTile(title: Text('Edit profile')),
            ListTile(title: Text('Change password')),
          ],
        ),
      ),
    );

    expect(find.text('ACCOUNT'), findsOneWidget);
    expect(find.text('Edit profile'), findsOneWidget);
    expect(find.text('Change password'), findsOneWidget);
  });

  testWidgets('3. OwnerBody keeps content within the owner width', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 1000);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      host(
        const OwnerBody(
          child: SizedBox(key: Key('body'), height: 10, width: double.infinity),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const Key('body'))).width,
      kOwnerContentWidth,
    );
  });

  testWidgets('4. DormCover without a photo shows the placeholder icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const DormCover(url: null, width: 80, height: 80)),
    );

    expect(find.byIcon(Icons.apartment_rounded), findsOneWidget);
  });
}
