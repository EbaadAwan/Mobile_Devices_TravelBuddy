import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'trip_plan.dart';

/// Local-only storage. SharedPreferences is already used in TravelBuddy.
/// This class deliberately uses its own keys, not the group's favourites keys.
class TripStore extends ChangeNotifier {
  TripStore._();
  static final TripStore instance = TripStore._();

  static const _tripsKey = 'brandon_trip_plans_v1';
  static const _nameKey = 'brandon_trip_name_v1';
  static const _budgetKey = 'brandon_trip_budget_v1';

  List<TripPlan> _trips = [];
  String _tripName = 'Toronto Trip';
  double _budget = 500;
  bool _loaded = false;
  String? _loadError;
  Future<void>? _loading;

  bool get loaded => _loaded;
  String? get loadError => _loadError;
  String get tripName => _tripName;
  double get budget => _budget;
  List<TripPlan> get trips => List.unmodifiable(_trips);
  List<TripPlan> get upcoming =>
      _trips.where((trip) => trip.visitAt.isAfter(DateTime.now())).toList()
        ..sort((a, b) => a.visitAt.compareTo(b.visitAt));

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_tripsKey);
      if (stored != null) {
        final list = jsonDecode(stored) as List<dynamic>;
        _trips = list
            .map((entry) => TripPlan.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ))
            .toList();
      }
      _tripName = prefs.getString(_nameKey) ?? _tripName;
      _budget = prefs.getDouble(_budgetKey) ?? _budget;
      _loadError = null;
    } catch (_) {
      _loadError = 'Saved trips could not be loaded. Please try again.';
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> retryLoad() async {
    _loading = null;
    _loaded = false;
    _loadError = null;
    notifyListeners();
    await load();
  }

  Future<void> upsert(TripPlan trip) async {
    await load();
    if (_loadError != null) throw StateError(_loadError!);
    final existing = List<TripPlan>.from(_trips);
    final index = _trips.indexWhere((item) => item.id == trip.id);
    if (index == -1) {
      _trips.add(trip);
    } else {
      _trips[index] = trip;
    }
    try {
      await _persistTrips();
      notifyListeners();
    } catch (_) {
      _trips = existing;
      rethrow;
    }
  }

  Future<void> remove(String id) async {
    await load();
    if (_loadError != null) throw StateError(_loadError!);
    final existing = List<TripPlan>.from(_trips);
    _trips.removeWhere((item) => item.id == id);
    try {
      await _persistTrips();
      notifyListeners();
    } catch (_) {
      _trips = existing;
      rethrow;
    }
  }

  Future<void> _persistTrips() async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(
      _tripsKey,
      jsonEncode(_trips.map((trip) => trip.toJson()).toList()),
    )) {
      throw StateError('Unable to save trips on this device.');
    }
  }

  Future<void> renameTrip(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('Enter a trip name.');
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_nameKey, trimmed)) {
      throw StateError('Unable to save trip name.');
    }
    _tripName = trimmed;
    notifyListeners();
  }

  Future<void> setBudget(double value) async {
    if (!value.isFinite || value < 0) {
      throw ArgumentError('Budget must be a non-negative number.');
    }
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setDouble(_budgetKey, value)) {
      throw StateError('Unable to save budget.');
    }
    _budget = value;
    notifyListeners();
  }
}
