import 'package:flutter_test/flutter_test.dart';
import 'package:travelbuddy/features/trips/trip_plan.dart';

void main() {
  test('a visit survives JSON serialization with its reminder ID', () {
    final original = TripPlan(
      id: 'visit-123',
      title: 'Museum morning',
      destinationName: 'Oshawa Museum',
      destinationLocation: 'Oshawa',
      visitAt: DateTime(2027, 1, 20, 10, 30),
      notes: 'Bring a camera',
    );
    final restored = TripPlan.fromJson(original.toJson());
    expect(restored.id, original.id);
    expect(restored.title, original.title);
    expect(restored.destinationName, original.destinationName);
    expect(restored.visitAt, original.visitAt);
    expect(restored.notes, original.notes);
    expect(restored.notificationId, original.notificationId);
  });

  test('copyWith changes one field without changing trip identity', () {
    final original = TripPlan(
      id: 'visit-123',
      title: 'Museum morning',
      destinationName: 'Oshawa Museum',
      visitAt: DateTime(2027, 1, 20, 10, 30),
    );
    final edited = original.copyWith(notes: 'Tickets booked');
    expect(edited.id, original.id);
    expect(edited.destinationName, original.destinationName);
    expect(edited.notes, 'Tickets booked');
  });
}
