import 'package:shared_preferences/shared_preferences.dart';

import '../domain/game_preferences.dart';
import '../domain/game_preferences_repository.dart';

/// Local-only settings storage. No cloud account or backend is required.
class SharedPreferencesGamePreferencesRepository
    implements GamePreferencesRepository {
  const SharedPreferencesGamePreferencesRepository();

  static const String keyReduceFlashes =
      'color_dodge.preferences.reduce_flashes';

  @override
  Future<GamePreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    return GamePreferences(
      reduceFlashes: prefs.getBool(keyReduceFlashes) ?? false,
    );
  }

  @override
  Future<void> save(GamePreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setBool(
      keyReduceFlashes,
      preferences.reduceFlashes,
    );
    if (!saved) {
      throw StateError('Could not persist player preferences');
    }
  }
}
