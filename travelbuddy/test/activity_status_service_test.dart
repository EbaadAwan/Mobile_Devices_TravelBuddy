import 'package:flutter_test/flutter_test.dart';
import 'package:travelbuddy/features/activity/activity_status_service.dart';

void main() {
  test('activity is unavailable before any credible data exists', () {
    final service = ActivityStatusService.instance;
    service.setUnavailable('Test Attraction');
    final initial = service.statusFor('Test Attraction');
    expect(initial.level, CrowdLevel.unavailable);
    expect(initial.source, ActivitySource.unavailable);
  });

  test('manual activity updates are identified as demo data', () {
    final service = ActivityStatusService.instance;
    service.setDemoStatus('Test Attraction', CrowdLevel.busy);
    final updated = service.statusFor('Test Attraction');
    expect(updated.level, CrowdLevel.busy);
    expect(updated.source, ActivitySource.demo);
    service.setUnavailable('Test Attraction');
  });
}
