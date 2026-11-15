import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/travel_notification_service.dart';
import '../trips/trip_plan.dart';
import '../trips/trip_store.dart';
import 'reminder_schedule.dart';

/// Sends previews and foreground timer events to the visible application.
class ReminderBannerBus extends ChangeNotifier {
  ReminderBannerBus._();
  static final ReminderBannerBus instance = ReminderBannerBus._();

  ReminderBannerMessage? _message;
  ReminderBannerMessage? get message => _message;

  void show(ReminderBannerMessage message) {
    _message = message;
    notifyListeners();
  }

  void preview(TripPlan? trip) => show(ReminderBannerMessage(
        title: 'TravelBuddy reminder preview',
        body: trip == null
            ? 'Your next visit will appear here.'
            : '${trip.destinationName} — open your planned visit',
        tripId: trip?.id,
      ));
}

class ReminderBannerMessage {
  const ReminderBannerMessage({
    required this.title,
    required this.body,
    this.tripId,
  });
  final String title;
  final String body;
  final String? tripId;
}

/// In-app banners require a running foreground process. Android's separately
/// scheduled notification handles delivery in the background / after exit.
class TravelBuddyReminderOverlay extends StatefulWidget {
  const TravelBuddyReminderOverlay({super.key, required this.child});
  final Widget child;

  @override
  State<TravelBuddyReminderOverlay> createState() =>
      _TravelBuddyReminderOverlayState();
}

class _TravelBuddyReminderOverlayState extends State<TravelBuddyReminderOverlay>
    with WidgetsBindingObserver {
  final _store = TripStore.instance;
  final _bus = ReminderBannerBus.instance;
  final Set<String> _shown = {};
  Timer? _next;
  Timer? _dismiss;
  ReminderBannerMessage? _visible;
  bool _inForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _store.addListener(_scheduleNext);
    _bus.addListener(_showBusMessage);
    _store.load().then((_) {
      if (mounted) _scheduleNext();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inForeground = state == AppLifecycleState.resumed;
    _scheduleNext();
  }

  void _scheduleNext() {
    _next?.cancel();
    if (!_inForeground || !_store.loaded || _store.loadError != null) return;
    final now = DateTime.now();
    final upcoming = <TripReminderEvent>[
      for (final trip in _store.upcoming)
        ...TripReminderSchedule.upcoming(trip, now: now),
    ]..sort((a, b) => a.at.compareTo(b.at));
    if (upcoming.isEmpty) return;
    final first = upcoming.first;
    final delay = first.at.difference(now);
    _next = Timer(delay, () {
      if (!mounted || !_inForeground) return;
      if (_shown.add('${first.notificationId}:${first.at.microsecondsSinceEpoch}')) {
        _bus.show(ReminderBannerMessage(
          title: first.title,
          body: first.body,
          tripId: first.tripId,
        ));
      }
      _scheduleNext();
    });
  }

  void _showBusMessage() {
    if (!mounted || !_inForeground) return;
    final message = _bus.message;
    if (message == null) return;
    _dismiss?.cancel();
    setState(() => _visible = message);
    _dismiss = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _visible = null);
    });
  }

  void _openVisit() {
    final id = _visible?.tripId;
    _dismiss?.cancel();
    setState(() => _visible = null);
    if (id != null) TravelNotificationService.instance.openTrip(id);
  }

  @override
  void dispose() {
    _next?.cancel();
    _dismiss?.cancel();
    _store.removeListener(_scheduleNext);
    _bus.removeListener(_showBusMessage);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          widget.child,
          if (_visible != null)
            Positioned(
              top: 0,
              left: 12,
              right: 12,
              child: SafeArea(
                child: Material(
                  color: const Color(0xFFE9FCFF),
                  elevation: 10,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active,
                            color: Color(0xFF007E91)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_visible!.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Text(_visible!.body,
                                  style: const TextStyle(fontSize: 12)),
                              if (_visible!.tripId != null)
                                TextButton(
                                  onPressed: _openVisit,
                                  child: const Text('View trip'),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Dismiss reminder',
                          onPressed: () {
                            _dismiss?.cancel();
                            setState(() => _visible = null);
                          },
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
}
