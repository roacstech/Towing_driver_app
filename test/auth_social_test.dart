import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:towing_driver/features/auth/screens/driver_login_screen.dart';
import 'package:towing_driver/features/auth/screens/driver_register_screen.dart';
import 'package:towing_driver/shared/widgets/google_logo.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('DriverLoginScreen renders Google and Apple social buttons',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: DriverLoginScreen(),
      ),
    );
    await tester.pump();

    // Verify "OR CONTINUE WITH" divider
    expect(find.text('OR CONTINUE WITH'), findsOneWidget);

    // Verify Google and Apple buttons
    expect(find.byType(GoogleLogo), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
    expect(find.byIcon(Icons.apple), findsOneWidget);
    expect(find.text('Apple'), findsOneWidget);
  });

  testWidgets('DriverRegisterScreen renders Google and Apple buttons on Step 1',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: DriverRegisterScreen(),
      ),
    );
    await tester.pump();

    // Verify "OR REGISTER WITH" divider
    expect(find.text('OR REGISTER WITH'), findsOneWidget);

    // Verify Google and Apple buttons on Registration Step 1
    expect(find.byType(GoogleLogo), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
    expect(find.byIcon(Icons.apple), findsOneWidget);
    expect(find.text('Apple'), findsOneWidget);
  });
}
