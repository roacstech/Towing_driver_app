import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:towing_driver/main.dart';
import 'package:towing_driver/features/home/screens/driver_home_screen.dart';
import 'package:towing_driver/features/navigation/screens/driver_main_shell.dart';
import 'package:towing_driver/features/jobs/services/driver_job_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'driver_is_online': false});
  });

  testWidgets('Driver App smoke test - launches and renders driver home shell', (WidgetTester tester) async {
    addTearDown(() {
      DriverJobService().stopDispatchPolling();
    });

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const TowingDriverApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(TowingDriverApp), findsOneWidget);
    expect(find.byType(DriverMainShell), findsOneWidget);
    expect(find.byType(DriverHomeScreen), findsOneWidget);
    expect(find.text('Vehicle Transport'), findsOneWidget);
  });
}
