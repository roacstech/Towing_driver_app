import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:towing_driver/main.dart';
import 'package:towing_driver/features/home/screens/driver_home_screen.dart';
import 'package:towing_driver/features/home/widgets/swipeable_request_card.dart';
import 'package:towing_driver/features/jobs/screens/request_list_screen.dart';
import 'package:towing_driver/features/jobs/screens/trip_details_screen.dart';
import 'package:towing_driver/features/jobs/services/driver_job_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'driver_is_online': false});
    DriverJobService().resetDemoRequests();
  });

  tearDown(() {
    DriverJobService().stopDispatchPolling();
  });

  testWidgets('Test Requests tab navigation from Driver Bottom Navigation', (WidgetTester tester) async {
    addTearDown(() => DriverJobService().stopDispatchPolling());
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const TowingDriverApp());
    await tester.pump(const Duration(milliseconds: 100));

    // Tap "Requests" tab in bottom navigation bar
    final requestsTab = find.text('Requests');
    expect(requestsTab, findsOneWidget);
    await tester.tap(requestsTab);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    // Verify RequestListScreen opened
    expect(find.byType(RequestListScreen), findsOneWidget);
    expect(find.text('Available Requests'), findsOneWidget);
  });

  testWidgets('Test Card Tap opens Trip Details Screen', (WidgetTester tester) async {
    addTearDown(() => DriverJobService().stopDispatchPolling());
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const TowingDriverApp());
    await tester.pump(const Duration(milliseconds: 100));

    // Tap the top card
    final cardFinder = find.byType(SwipeableRequestCard);
    expect(cardFinder, findsOneWidget);
    await tester.tap(cardFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    // Verify TripDetailsScreen opened
    expect(find.byType(TripDetailsScreen), findsOneWidget);
  });

  testWidgets('Test Manual Pass button advances to next card in stack', (WidgetTester tester) async {
    addTearDown(() => DriverJobService().stopDispatchPolling());
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const TowingDriverApp());
    await tester.pump(const Duration(milliseconds: 100));

    final initialCount = DriverJobService().availableRequests.length;
    expect(initialCount, greaterThan(1));

    // Tap "Pass" button
    final passButton = find.text('Pass');
    expect(passButton, findsOneWidget);
    await tester.tap(passButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    // Queue count reduced by 1
    expect(DriverJobService().availableRequests.length, initialCount - 1);
  });
}
