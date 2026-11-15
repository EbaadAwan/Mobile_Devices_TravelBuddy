/// Per-visit reminder settings, persisted within TripPlan JSON.
/// Existing visits use the default 60/30/5 minute schedule.
class ReminderPreferences {
  const ReminderPreferences({
    this.firstMinutes = 60,
    this.firstEnabled = true,
    this.thirtyEnabled = true,
    this.fiveEnabled = true,
  }) : assert(firstMinutes == 60 || firstMinutes == 90);

  final int firstMinutes;
  final bool firstEnabled;
  final bool thirtyEnabled;
  final bool fiveEnabled;

  List<int> get enabledMinutes => [
        if (firstEnabled) firstMinutes,
        if (thirtyEnabled) 30,
        if (fiveEnabled) 5,
      ];

  ReminderPreferences copyWith({
    int? firstMinutes,
    bool? firstEnabled,
    bool? thirtyEnabled,
    bool? fiveEnabled,
  }) =>
      ReminderPreferences(
        firstMinutes: firstMinutes ?? this.firstMinutes,
        firstEnabled: firstEnabled ?? this.firstEnabled,
        thirtyEnabled: thirtyEnabled ?? this.thirtyEnabled,
        fiveEnabled: fiveEnabled ?? this.fiveEnabled,
      );

  Map<String, dynamic> toJson() => {
        'firstMinutes': firstMinutes,
        'firstEnabled': firstEnabled,
        'thirtyEnabled': thirtyEnabled,
        'fiveEnabled': fiveEnabled,
      };

  factory ReminderPreferences.fromJson(Object? value) {
    if (value is! Map) return const ReminderPreferences();
    final first = value['firstMinutes'];
    return ReminderPreferences(
      firstMinutes: first == 90 ? 90 : 60,
      firstEnabled: value['firstEnabled'] is bool
          ? value['firstEnabled'] as bool
          : true,
      thirtyEnabled: value['thirtyEnabled'] is bool
          ? value['thirtyEnabled'] as bool
          : true,
      fiveEnabled: value['fiveEnabled'] is bool
          ? value['fiveEnabled'] as bool
          : true,
    );
  }
}
