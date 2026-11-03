import 'package:flutter_test/flutter_test.dart';
import 'package:travelbuddy/main.dart';

void main() {
  testWidgets('TravelBuddy shell shows existing tabs', (tester) async {
    await tester.pumpWidget(const TravelBuddyApp());
    expect(find.text('TravelBuddy'), findsOneWidget);
    expect(find.text('Trip Planner'), findsOneWidget);
  });
}
