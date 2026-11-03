import 'package:flutter/foundation.dart';

/// Crowd level, NOT an Android notification/live-activity API.
enum CrowdLevel { unavailable, quiet, moderate, busy }
enum ActivitySource { unavailable, demo, external }

class AttractionActivity {
  const AttractionActivity({
    required this.level,
    required this.source,
    this.updatedAt,
  });

  final CrowdLevel level;
  final ActivitySource source;
  final DateTime? updatedAt;

  String get label => switch (level) {
        CrowdLevel.quiet => 'Quiet',
        CrowdLevel.moderate => 'Moderate',
        CrowdLevel.busy => 'Busy',
        CrowdLevel.unavailable => 'Unavailable',
      };
}

/// No crowd API is provided by the project. Start as unavailable; any manual
/// changes are explicitly DEMO data. `updateFromApi` is the future integration
/// point when a genuine, licensed crowd-information source is available.
class ActivityStatusService extends ChangeNotifier {
  ActivityStatusService._();
  static final ActivityStatusService instance = ActivityStatusService._();
  final Map<String, AttractionActivity> _statuses = {};

  AttractionActivity statusFor(String name) =>
      _statuses[name] ??
      const AttractionActivity(
        level: CrowdLevel.unavailable,
        source: ActivitySource.unavailable,
      );

  void setDemoStatus(String name, CrowdLevel level) {
    _statuses[name] = AttractionActivity(
      level: level,
      source: ActivitySource.demo,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  void updateFromApi(String name, CrowdLevel level) {
    _statuses[name] = AttractionActivity(
      level: level,
      source: ActivitySource.external,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  void setUnavailable(String name) {
    _statuses.remove(name);
    notifyListeners();
  }
}
