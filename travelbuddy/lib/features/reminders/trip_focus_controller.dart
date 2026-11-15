import 'package:flutter/foundation.dart';

/// Carries a notification's visit ID to the planner after tab navigation.
class TripFocusController extends ChangeNotifier {
  TripFocusController._();
  static final TripFocusController instance = TripFocusController._();

  String? _tripId;
  String? get tripId => _tripId;

  void focus(String id) {
    if (id.isEmpty) return;
    _tripId = id;
    notifyListeners();
  }
}
