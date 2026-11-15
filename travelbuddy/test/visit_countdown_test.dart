import 'package:flutter_test/flutter_test.dart';
import 'package:travelbuddy/features/reminders/visit_countdown.dart';

void main() {
  final now = DateTime(2027, 4, 10, 12);
  test('friendly time remaining labels', () {
    expect(visitCountdown(now.add(const Duration(days: 2)), now),
        'In 2 days');
    expect(visitCountdown(now.add(const Duration(hours: 2)), now),
        'In 2 hours');
    expect(visitCountdown(now.add(const Duration(minutes: 30)), now),
        'In 30 minutes');
    expect(visitCountdown(now.add(const Duration(minutes: 5)), now),
        'Starting soon');
    expect(visitCountdown(now.subtract(const Duration(minutes: 1)), now),
        'Visit time reached');
  });
}
