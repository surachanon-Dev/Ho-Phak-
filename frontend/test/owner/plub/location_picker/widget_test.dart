// ผู้รับผิดชอบ: Plub (เจ้าของหอ)
// widget test: หน้าเลือกตำแหน่งหอบนแผนที่
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/modules/owner/location_picker/view/location_picker_screen.dart';
import 'package:latlong2/latlong.dart';

void main() {
  testWidgets('1. Opens with the title and a Confirm location button', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LocationPickerScreen()));
    await tester.pump();

    expect(find.text('Set dorm location'), findsOneWidget);
    expect(find.text('Confirm location'), findsOneWidget);
  });

  testWidgets('2. Confirm location returns the chosen point', (tester) async {
    const start = LatLng(19.95, 99.89);
    LatLng? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await Navigator.of(context).push<LatLng>(
                MaterialPageRoute(
                  builder: (_) => const LocationPickerScreen(initial: start),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Confirm location'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(result, isNotNull);
    expect(result!.latitude, closeTo(start.latitude, 0.0001));
    expect(result!.longitude, closeTo(start.longitude, 0.0001));
  });
}
