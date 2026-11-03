import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as tz;

import '../features/trips/trip_plan.dart';

/// Android local notifications. These are NOT Firebase/remote push messages.
/// The Android emulator is the primary demonstration target.
class TravelNotificationService {
  TravelNotificationService._();
  static final TravelNotificationService instance = TravelNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  Future<void>? _initializing;
  bool _timezoneReady = false;
  ValueChanged<int>? _onSelectTab;
  final Map<String, DateTime> _lastFavoriteAlert = {};

  static const _reminderDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'travelbuddy_trip_reminders',
      'Trip reminders',
      channelDescription: 'Reminders for your upcoming scheduled visits',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );
  static const _favoriteDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'travelbuddy_favorites',
      'Favorite alerts',
      channelDescription: 'Confirmation when attractions are favorited',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
  );

  bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> initialize({ValueChanged<int>? onSelectTab}) {
    if (onSelectTab != null) _onSelectTab = onSelectTab;
    if (!isAndroid) return Future.value();
    return _initializing ??= _initializeAndroid();
  }

  Future<void> _initializeAndroid() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        _openFromPayload(response.payload);
      },
    );
    timezone_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
      _timezoneReady = true;
    } catch (error) {
      // A local test alert can still work if timezone detection fails.
      debugPrint('TravelBuddy timezone unavailable: $error');
    }
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _openFromPayload(launch?.notificationResponse?.payload);
    }
  }

  void _openFromPayload(String? payload) {
    if (payload == null) return;
    if (payload.startsWith('trip:')) _onSelectTab?.call(2);
    if (payload.startsWith('favorite:')) _onSelectTab?.call(1);
  }

  Future<bool> requestPermission() async {
    if (!isAndroid) return false;
    await initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final allowed = await android?.requestNotificationsPermission();
    return allowed ?? false;
  }

  /// The proposal asks for a reminder a few days before a trip. For visits
  /// less than two days away, use a one-minute-before reminder for a demo.
  /// Inexact alarms can be delayed by Android power-management policies.
  DateTime? reminderTimeFor(DateTime visitAt) {
    final now = DateTime.now();
    if (!visitAt.isAfter(now)) return null;
    final gap = visitAt.difference(now);
    if (gap > const Duration(days: 2, minutes: 2)) {
      return visitAt.subtract(const Duration(days: 2));
    }
    if (gap > const Duration(minutes: 2)) {
      return visitAt.subtract(const Duration(minutes: 1));
    }
    return null;
  }

  /// Returns false if notifications are disabled, timezone detection failed,
  /// or the trip is too soon. Saving the trip is independent of reminders.
  Future<bool> scheduleTrip(TripPlan trip) async {
    if (!isAndroid) return false;
    await initialize();
    await _plugin.cancel(trip.notificationId); // Prevent duplicate reminders.
    final at = reminderTimeFor(trip.visitAt);
    if (at == null || !_timezoneReady || !await requestPermission()) {
      return false;
    }
    await _plugin.zonedSchedule(
      trip.notificationId,
      'TravelBuddy trip reminder',
      '${trip.destinationName} — ${trip.title}',
      tz.TZDateTime.from(at, tz.local),
      _reminderDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'trip:${trip.id}',
    );
    return true;
  }

  Future<void> cancelTrip(TripPlan trip) async {
    if (!isAndroid) return;
    await initialize();
    await _plugin.cancel(trip.notificationId);
  }

  /// This is a LOCAL alert about the user's own favourite action.
  /// It does not claim the attraction has released new/live information.
  Future<bool> notifyFavoriteSaved(String attractionName) async {
    if (!isAndroid) return false;
    final now = DateTime.now();
    final last = _lastFavoriteAlert[attractionName];
    if (last != null && now.difference(last) < const Duration(seconds: 5)) {
      return false;
    }
    if (!await requestPermission()) return false;
    _lastFavoriteAlert[attractionName] = now;
    await _plugin.show(
      900001,
      'Saved to favourites',
      '$attractionName is in your saved places.',
      _favoriteDetails,
      payload: 'favorite:$attractionName',
    );
    return true;
  }

  Future<bool> showTestNotification() async {
    if (!await requestPermission()) return false;
    await _plugin.show(
      900002,
      'TravelBuddy notifications are working',
      'This is a local Android test notification.',
      _reminderDetails,
      payload: 'trip:test',
    );
    return true;
  }
}
