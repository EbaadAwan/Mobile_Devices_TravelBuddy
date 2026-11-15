import '../trips/trip_plan.dart';

/// A device-local reminder. Time values are derived from the visit start time.
class TripReminderEvent {
  const TripReminderEvent({
    required this.tripId,
    required this.notificationId,
    required this.minutesBefore,
    required this.at,
    required this.title,
    required this.body,
  });

  final String tripId;
  final int notificationId;
  final int minutesBefore;
  final DateTime at;
  final String title;
  final String body;

  String get payload => 'trip:$tripId';
}

class TripReminderSchedule {
  const TripReminderSchedule._();

  static const slots = ['early', 'half-hour', 'five-minute'];

  /// Stable IDs even if the user changes the first reminder from 60 to 90.
  static int idFor(String tripId, String slot) {
    var hash = 0x811c9dc5;
    for (final codeUnit in '$tripId:reminder:$slot'.codeUnits) {
      hash = ((hash ^ codeUnit) * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }

  static List<int> allIds(String tripId) => [
        for (final slot in slots) idFor(tripId, slot),
      ];

  static List<TripReminderEvent> upcoming(TripPlan trip, {DateTime? now}) {
    final instant = now ?? DateTime.now();
    final preferences = trip.reminders;
    final options = <(String, int)>[
      if (preferences.firstEnabled) ('early', preferences.firstMinutes),
      if (preferences.thirtyEnabled) ('half-hour', 30),
      if (preferences.fiveEnabled) ('five-minute', 5),
    ];
    final result = <TripReminderEvent>[];
    for (final (slot, minutes) in options) {
      final at = trip.visitAt.subtract(Duration(minutes: minutes));
      if (!at.isAfter(instant)) continue; // Never schedule in the past.
      result.add(TripReminderEvent(
        tripId: trip.id,
        notificationId: idFor(trip.id, slot),
        minutesBefore: minutes,
        at: at,
        title: 'TravelBuddy · Visit in $minutes minutes',
        body: '${trip.destinationName} — ${_formatVisit(trip.visitAt)}',
      ));
    }
    return result..sort((a, b) => a.at.compareTo(b.at));
  }

  static String _formatVisit(DateTime at) {
    final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
    final minute = at.minute.toString().padLeft(2, '0');
    final period = at.hour < 12 ? 'AM' : 'PM';
    return '${at.year}-${at.month.toString().padLeft(2, '0')}-'
        '${at.day.toString().padLeft(2, '0')} at $hour:$minute $period';
  }
}
