import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:towing_driver/core/localization/driver_language_service.dart';
import 'package:towing_driver/features/profile/screens/driver_profile_screen.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DriverLanguageService().init();
  });

  test('DriverLanguageService translates keys correctly for English and Tamil', () async {
    final service = DriverLanguageService();
    await service.setLanguage('English');
    expect(service.tr('my_profile'), 'My Profile');
    expect(service.tr('logout'), 'Logout');

    await service.setLanguage('தமிழ் (Tamil)');
    expect(service.tr('my_profile'), 'என் சுயவிவரம்');
    expect(service.tr('logout'), 'வெளியேறு');
    expect(service.tr('language_settings'), 'மொழி அமைப்புகள்');
  });

  testWidgets('DriverProfileScreen dynamically translates to Tamil when language is changed',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Initial English rendering
    await DriverLanguageService().setLanguage('English');
    await tester.pumpWidget(
      const MaterialApp(
        home: DriverProfileScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('My Profile'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
    expect(find.text('Language Settings'), findsOneWidget);

    // Change language to Tamil
    await DriverLanguageService().setLanguage('தமிழ் (Tamil)');
    await tester.pumpWidget(
      const MaterialApp(
        home: DriverProfileScreen(),
      ),
    );
    await tester.pump();

    // Verify Tamil translations appear
    expect(find.text('என் சுயவிவரம்'), findsOneWidget);
    expect(find.text('வெளியேறு'), findsOneWidget);
    expect(find.text('மொழி அமைப்புகள்'), findsOneWidget);
  });
}
