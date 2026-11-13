import 'package:flutter_test/flutter_test.dart';
import 'package:travelbuddy/features/reminders/reminder_schedule.dart';
import 'package:travelbuddy/features/trips/reminder_preferences.dart';
import 'package:travelbuddy/features/trips/trip_plan.dart';

void main() {
  final visit = DateTime(2027, 3, 25, 14, 30);
  TripPlan makeTrip({ReminderPreferences? reminders}) => TripPlan(
        id: 'trip-abc',
        title: 'Afternoon visit',
        destinationName: 'CN Tower',
        visitAt: visit,
        reminders: reminders ?? const ReminderPreferences(),
      );

  test('defaults are 60, 30 and 5 minutes, with distinct stable IDs', () {
    final events = TripReminderSchedule.upcoming(
      makeTrip(),
      now: DateTime(2027, 3, 25, 12),
    );
    expect(events.map((e) => e.minutesBefore), [60, 30, 5]);
    expect(events.map((e) => e.at), [
      DateTime(2027, 3, 25, 13, 30),
      DateTime(2027, 3, 25, 14),
      DateTime(2027, 3, 25, 14, 25),
    ]);
    expect(events.map((e) => e.notificationId).toSet().length, 3);
    expect(events.first.body, contains('CN Tower'));
    expect(events.first.body, contains('2:30 PM'));
    expect(events.first.payload, 'trip:trip-abc');
  });

  test('90-minute choice does not change the early notification ID', () {
    final defaultEvents = TripReminderSchedule.upcoming(
      makeTrip(),
      now: DateTime(2027, 3, 25, 12),
    );
    final changedEvents = TripReminderSchedule.upcoming(
      makeTrip(reminders: const ReminderPreferences(firstMinutes: 90)),
      now: DateTime(2027, 3, 25, 12),
    );
    expect(changedEvents.first.minutesBefore, 90);
    expect(changedEvents.first.at, DateTime(2027, 3, 25, 13));
    expect(changedEvents.first.notificationId, defaultEvents.first.notificationId);
  });

  test('disabled options and past reminders are excluded', () {
    final events = TripReminderSchedule.upcoming(
      makeTrip(reminders: const ReminderPreferences(
        firstEnabled: false,
        thirtyEnabled: true,
        fiveEnabled: true,
      )),
      now: DateTime(2027, 3, 25, 14, 10),
    );
    expect(events.map((e) => e.minutesBefore), [5]);
  });

  test('an all-disabled schedule has zero notifications', () {
    final events = TripReminderSchedule.upcoming(
      makeTrip(reminders: const ReminderPreferences(
        firstEnabled: false,
        thirtyEnabled: false,
        fiveEnabled: false,
      )),
      now: DateTime(2027, 3, 25, 12),
    );
    expect(events, isEmpty);
  });

  test('reminder preferences survive JSON and old visits get defaults', () {
    const saved = ReminderPreferences(
      firstMinutes: 90,
      thirtyEnabled: false,
    );
    final original = makeTrip(reminders: saved);
    final restored = TripPlan.fromJson(original.toJson());
    expect(restored.reminders.firstMinutes, 90);
    expect(restored.reminders.thirtyEnabled, false);

    final legacy = original.toJson()..remove('reminders');
    final legacyRestored = TripPlan.fromJson(legacy);
    expect(legacyRestored.reminders.enabledMinutes, [60, 30, 5]);
  });

  test('copyWith keeps visit identity and updates reminder preferences', () {
    final trip = makeTrip();
    final edited = trip.copyWith(
      reminders: trip.reminders.copyWith(fiveEnabled: false),
    );
    expect(edited.id, trip.id);
    expect(edited.notificationId, trip.notificationId);
    expect(edited.reminders.enabledMinutes, [60, 30]);
  });
}
