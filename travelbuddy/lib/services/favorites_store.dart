import 'package:shared_preferences/shared_preferences.dart';

/// Persists the names of the attractions the user saved.
class FavoritesStore {
  FavoritesStore._();

  static final FavoritesStore instance = FavoritesStore._();
  static const _key = 'favorite_attraction_names';

  Future<Set<String>?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final values = preferences.getStringList(_key);
    return values?.toSet();
  }

  Future<void> save(Set<String> names) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_key, names.toList()..sort());
  }
}
