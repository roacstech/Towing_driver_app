import 'package:flutter_test/flutter_test.dart';
import 'package:towing_driver/main.dart';

void main() {
  testWidgets('Driver App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TowingDriverApp());
    expect(find.byType(TowingDriverApp), findsOneWidget);
  });
}
