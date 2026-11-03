/// A single scheduled visit. All dates are stored as local wall-clock times.
class TripPlan {
  const TripPlan({
    required this.id,
    required this.title,
    required this.destinationName,
    required this.visitAt,
    this.destinationLocation = '',
    this.notes = '',
  });

  final String id;
  final String title;
  final String destinationName;
  final String destinationLocation;
  final DateTime visitAt;
  final String notes;

  TripPlan copyWith({
    String? title,
    String? destinationName,
    String? destinationLocation,
    DateTime? visitAt,
    String? notes,
  }) => TripPlan(
        id: id,
        title: title ?? this.title,
        destinationName: destinationName ?? this.destinationName,
        destinationLocation: destinationLocation ?? this.destinationLocation,
        visitAt: visitAt ?? this.visitAt,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'destinationName': destinationName,
        'destinationLocation': destinationLocation,
        'visitAt': visitAt.toIso8601String(),
        'notes': notes,
      };

  factory TripPlan.fromJson(Map<String, dynamic> json) => TripPlan(
        id: json['id'] as String,
        title: json['title'] as String,
        destinationName: json['destinationName'] as String,
        destinationLocation: json['destinationLocation'] as String? ?? '',
        visitAt: DateTime.parse(json['visitAt'] as String),
        notes: json['notes'] as String? ?? '',
      );

  /// A stable ID across launches, used to update/cancel one reminder.
  int get notificationId {
    var hash = 0x811c9dc5;
    for (final codeUnit in id.codeUnits) {
      hash = ((hash ^ codeUnit) * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }
}
