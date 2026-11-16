import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopak_frontend/screens/owner/change_password_screen.dart';
import 'package:hopak_frontend/screens/owner/edit_profile_screen.dart';
import 'package:hopak_frontend/screens/owner/notification_settings_screen.dart';
import 'package:hopak_frontend/services/app_services.dart';
import 'package:hopak_frontend/services/owner_extras.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('notification settings: toggles persist', (tester) async {
    final services = AppServices();
    await tester.pumpWidget(
      MaterialApp(home: NotificationSettingsScreen(services: services)),
    );
    await tester.pumpAndSettle();
    expect(find.text('New messages'), findsOneWidget);
    expect(find.text('New reviews'), findsOneWidget);

    await tester.tap(find.text('New reviews'));
    await tester.pumpAndSettle();
    final p = await services.extras.notificationPrefs();
    expect(p.reviews, isTrue);
  });

  testWidgets('change password: validates before saving', (tester) async {
    final services = AppServices();
    await tester.pumpWidget(
      MaterialApp(home: ChangePasswordScreen(services: services)),
    );
    await tester.tap(find.text('Update password'));
    await tester.pump();
    expect(find.text('Enter your current password'), findsOneWidget);
    expect(find.text('Use at least 8 characters'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'oldpass1');
    await tester.enterText(fields.at(1), 'newpass123');
    await tester.enterText(fields.at(2), 'different');
    await tester.tap(find.text('Update password'));
    await tester.pump();
    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('edit profile: save disabled until something changes, '
      'phone change asks for password', (tester) async {
    final services = AppServices();
    await tester.pumpWidget(
      MaterialApp(
        home: EditProfileScreen(
          services: services,
          profile: const OwnerProfile(
            firstName: 'Somchai',
            surname: 'Jaidee',
            phone: '0812345678',
          ),
        ),
      ),
    );
    FilledButton save() => tester.widget<FilledButton>(find.byType(FilledButton));
    expect(save().onPressed, isNull);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Somchai2');
    await tester.pump();
    expect(save().onPressed, isNotNull);

    await tester.enterText(fields.at(2), '0819990000');
    await tester.pump();
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(
      find.text('Enter your password to change your phone number'),
      findsOneWidget,
    );
  });
}
