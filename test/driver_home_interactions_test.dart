import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:towing_driver/features/auth/services/driver_auth_service.dart';
import 'package:towing_driver/features/home/widgets/swipeable_request_card.dart';
import 'package:towing_driver/features/jobs/models/tow_job.dart';
import 'package:towing_driver/features/jobs/screens/request_list_screen.dart';
import 'package:towing_driver/features/jobs/screens/trip_details_screen.dart';
import 'package:towing_driver/features/jobs/services/driver_job_service.dart';
import 'package:towing_driver/features/navigation/screens/driver_main_shell.dart';

TowJob _createTestJob({required String id, String title = 'Vehicle Transport'}) {
  return TowJob(
    id: id,
    serviceTitle: title,
    requestType: 'Vehicle Transport',
    vehicleName: 'Ford F-150',
    licensePlate: 'MD-8492',
    pickupAddress: '7800 Georgia Ave, Silver Spring, MD',
    dropAddress: '4521 Lee Hwy, Arlington, VA',
    pickupLat: 38.9877,
    pickupLng: -77.0270,
    dropLat: 38.8950,
    dropLng: -77.1150,
    distanceToPickup: '4.4 mi',
    pickupEta: '12 min',
    tripDuration: '28 min',
    customerName: 'Marcus Bennett',
    customerPhone: '+1 (555) 782-1200',
    customerRating: 4.95,
    totalCost: '\$180.00',
    estimatedPayout: 180.00,
    etaOrDuration: '12 min ETA (4.4 mi)',
    status: JobStatus.pending,
    createdAt: DateTime.now(),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'driver_is_logged_in': true,
      'driver_is_online': true,
    });
    DriverAuthService().isLoggedInNotifier.value = true;
    DriverJobService().toggleOnlineStatus(true);
    DriverJobService().resetDemoRequests();
  });

  tearDown(() {
    DriverJobService().stopDispatchPolling();
  });

  testWidgets('Test online driver starts with 0 demo requests and shows Dispatch Radar Active', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: DriverMainShell()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    // Zero demo requests exist
    expect(DriverJobService().availableRequests, isEmpty);
    expect(find.text('Looking for Nearby Requests'), findsOneWidget);
    expect(find.text('DISPATCH RADAR ACTIVE'), findsOneWidget);
  });

  testWidgets('Test Requests tab navigation from Driver Bottom Navigation', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: DriverMainShell()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    // Tap "Requests" tab in bottom navigation bar
    final requestsTab = find.text('Requests');
    expect(requestsTab, findsOneWidget);
    await tester.tap(requestsTab);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    // Verify RequestListScreen opened
    expect(find.byType(RequestListScreen), findsOneWidget);
    expect(find.text('Available Requests'), findsOneWidget);
  });

  testWidgets('Test Card Tap opens Trip Details Screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);

    final testJob = _createTestJob(id: 'TOW-1001');
    DriverJobService().availableRequestsNotifier.value = [testJob];
    DriverJobService().selectedRequestNotifier.value = testJob;

    await tester.pumpWidget(const MaterialApp(home: DriverMainShell()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    // Tap the top card
    final cardFinder = find.byType(SwipeableRequestCard);
    expect(cardFinder, findsWidgets);
    await tester.tap(cardFinder.first, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Verify TripDetailsScreen opened
    expect(find.byType(TripDetailsScreen), findsOneWidget);
  });

  testWidgets('Test Manual Pass button advances to next card in stack', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);

    final job1 = _createTestJob(id: 'TOW-1001');
    final job2 = _createTestJob(id: 'TOW-1002');
    DriverJobService().availableRequestsNotifier.value = [job1, job2];
    DriverJobService().selectedRequestNotifier.value = job1;

    await tester.pumpWidget(const MaterialApp(home: DriverMainShell()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final initialCount = DriverJobService().availableRequests.length;
    expect(initialCount, equals(2));

    // Drag sheet up to reveal action buttons
    await tester.drag(find.byType(SwipeableRequestCard).first, const Offset(0, -300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap circular Pass button with close icon
    final passButton = find.byIcon(Icons.close_rounded);
    expect(passButton, findsWidgets);
    await tester.tap(passButton.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Queue count reduced by 1
    expect(DriverJobService().availableRequests.length, initialCount - 1);
  });

  testWidgets('Test online and offline toggle switch updates driver status', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: DriverMainShell()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    // Starts online
    expect(DriverJobService().driver.isOnline, isTrue);
    expect(find.text('ON DUTY'), findsOneWidget);

    // Tap the top status pill to toggle offline
    final onlinePill = find.text('ON DUTY');
    await tester.tap(onlinePill);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Now offline
    expect(DriverJobService().driver.isOnline, isFalse);
    expect(find.text('OFF DUTY'), findsOneWidget);
    expect(find.text("You're Currently Offline"), findsOneWidget);

    // Tap the top status pill again to toggle back online
    final offlinePill = find.text('OFF DUTY');
    await tester.tap(offlinePill);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Back online
    expect(DriverJobService().driver.isOnline, isTrue);
    expect(find.text('ON DUTY'), findsOneWidget);
  });

  testWidgets('Test Requests page renders full card with side-by-side Pass and Accept buttons', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);

    final job1 = _createTestJob(id: 'TOW-1001');
    DriverJobService().availableRequestsNotifier.value = [job1];
    DriverJobService().selectedRequestNotifier.value = job1;

    await tester.pumpWidget(const MaterialApp(home: DriverMainShell()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    // Navigate to Requests tab
    await tester.tap(find.text('Requests'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    // Verify Available Requests page is open
    expect(find.text('Available Requests'), findsOneWidget);

    // Verify full card elements are present
    expect(find.text('Est. Earnings'), findsWidgets);
    expect(find.text('PICKUP'), findsWidgets);
    expect(find.text('DROPOFF'), findsWidgets);

    // Verify Accept button and Pass button are rendered
    expect(find.text('Accept'), findsWidgets);
    expect(find.byIcon(Icons.close_rounded), findsWidgets);
  });

  testWidgets('Test Earnings tab Weekly Performance day-wise and week-wise navigation', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: DriverMainShell()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    // Navigate to Earnings tab
    await tester.tap(find.text('Earnings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    // Verify Earnings screen rendered
    expect(find.text('Driver Earnings'), findsOneWidget);
    expect(find.text('Weekly Performance'), findsOneWidget);
    expect(find.text('Oct 23 - Oct 29'), findsOneWidget);

    // Initial selected day is Saturday, Oct 28
    expect(find.text('Saturday, Oct 28'), findsOneWidget);
    expect(find.text('\$415.00'), findsWidgets);

    // Tap Prev Day button
    final prevDayBtn = find.text('Prev');
    expect(prevDayBtn, findsOneWidget);
    await tester.tap(prevDayBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    // Now Friday, Oct 27 is selected
    expect(find.text('Friday, Oct 27'), findsOneWidget);
    expect(find.text('\$340.00'), findsWidgets);

    // Tap Wed in the bar chart
    await tester.tap(find.text('Wed'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    // Wednesday, Oct 25 is now selected
    expect(find.text('Wednesday, Oct 25'), findsOneWidget);
    expect(find.text('\$360.00'), findsWidgets);
  });
}

